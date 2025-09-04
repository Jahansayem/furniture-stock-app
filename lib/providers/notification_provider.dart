import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../utils/logger.dart';

class NotificationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  List<AppNotification> _notifications = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AppNotification> get notifications => _notifications;

  // Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Fetch notifications for current user
  Future<void> fetchNotifications() async {
    _setLoading(true);
    _clearError();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return;
      }

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      _notifications = (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      _setError('Failed to fetch notifications: ${e.toString()}');
    }

    _setLoading(false);
  }

  // Add a new notification
  Future<bool> addNotification({
    required String title,
    required String message,
    required String type,
    String? data,
    String? userId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      final targetUserId = userId ?? user?.id;

      if (targetUserId == null) return false;

      final response = await _supabase
          .from('notifications')
          .insert({
            'title': title,
            'message': message,
            'type': type,
            'data': data,
            'user_id': targetUserId,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final newNotification = AppNotification.fromJson(response);

      // Only add to local list if it's for current user
      if (targetUserId == user?.id) {
        _notifications.insert(0, newNotification);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to add notification: ${e.toString()}');
      return false;
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);

      // Update local list
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to mark notification as read: ${e.toString()}');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      // Update local list
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to mark all notifications as read: ${e.toString()}');
      return false;
    }
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Add system notifications for low stock
  Future<void> checkLowStock() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // This would typically be called periodically or when stock changes
      final response = await _supabase.rpc('get_low_stock_products');

      final lowStockProducts = response as List;

      for (final product in lowStockProducts) {
        await addNotification(
          title: 'Low Stock Alert',
          message:
              '${product['product_name']} is running low (${product['total_quantity']} remaining)',
          type: 'low_stock',
          data:
              '{"product_id": "${product['id']}", "quantity": ${product['total_quantity']}}',
        );
      }
    } catch (e) {
      // Silently fail for now
      AppLogger.error('Error checking low stock', error: e);
    }
  }
}
