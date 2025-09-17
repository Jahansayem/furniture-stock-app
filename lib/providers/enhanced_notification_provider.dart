import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/logger.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.data,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] as bool,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

class EnhancedNotificationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  RealtimeChannel? _notificationChannel;
  bool _isSubscriptionActive = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isSubscriptionActive => _isSubscriptionActive;

  Future<void> fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _notifications = (response as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to mark notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('is_read', false);

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(
                isRead: true,
                readAt: DateTime.now(),
              ))
          .toList();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to mark all notifications as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete notification: $e');
      return false;
    }
  }

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
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Initialize realtime subscription for notifications
  Future<void> initializeRealtimeSubscription() async {
    if (_isSubscriptionActive) return; // Prevent duplicate subscriptions
    
    final user = _supabase.auth.currentUser;
    if (user == null) {
      AppLogger.warning('No authenticated user - cannot subscribe to notifications');
      return;
    }

    try {
      // Remove existing subscription if any
      await _notificationChannel?.unsubscribe();

      // Create new subscription
      _notificationChannel = _supabase
          .channel('notifications_${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.id,
            ),
            callback: (payload) {
              AppLogger.info('New notification received via realtime: ${payload.newRecord}');
              _handleNewNotification(payload.newRecord);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.id,
            ),
            callback: (payload) {
              AppLogger.info('Notification updated via realtime: ${payload.newRecord}');
              _handleUpdatedNotification(payload.newRecord);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.id,
            ),
            callback: (payload) {
              AppLogger.info('Notification deleted via realtime: ${payload.oldRecord}');
              _handleDeletedNotification(payload.oldRecord);
            },
          )
          .subscribe();

      _isSubscriptionActive = true;
      AppLogger.info('Realtime subscription for notifications initialized');
    } catch (e) {
      AppLogger.error('Error initializing realtime subscription', error: e);
      _isSubscriptionActive = false;
    }
  }

  // Handle new notification from realtime
  void _handleNewNotification(Map<String, dynamic> data) {
    try {
      final notification = NotificationModel.fromJson(data);
      _notifications.insert(0, notification); // Add to beginning
      notifyListeners();
      AppLogger.debug('New notification added to local state');
    } catch (e) {
      AppLogger.error('Error handling new notification', error: e);
    }
  }

  // Handle updated notification from realtime
  void _handleUpdatedNotification(Map<String, dynamic> data) {
    try {
      final updatedNotification = NotificationModel.fromJson(data);
      final index =
          _notifications.indexWhere((n) => n.id == updatedNotification.id);

      if (index != -1) {
        _notifications[index] = updatedNotification;
        notifyListeners();
        AppLogger.debug('Notification updated in local state');
      }
    } catch (e) {
      AppLogger.error('Error handling updated notification', error: e);
    }
  }

  // Handle deleted notification from realtime
  void _handleDeletedNotification(Map<String, dynamic> data) {
    try {
      final deletedId = data['id'] as String;
      _notifications.removeWhere((n) => n.id == deletedId);
      notifyListeners();
      AppLogger.debug('Notification removed from local state');
    } catch (e) {
      AppLogger.error('Error handling deleted notification', error: e);
    }
  }

  // Subscribe to stock level changes for automatic notifications
  Future<void> subscribeToStockChanges() async {
    try {
      _supabase
          .channel('stock_alerts')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'stock_levels',
            callback: (payload) async {
              final stockData = payload.newRecord;
              final currentLevel = stockData['current_level'] as int?;
              final minLevel = stockData['minimum_level'] as int?;

              if (currentLevel != null &&
                  minLevel != null &&
                  currentLevel <= minLevel) {
                AppLogger.warning('Stock level alert: Product ${stockData['product_id']} is below minimum');

                // Create notification in database (which will trigger realtime update)
                await _createStockAlert(stockData);
              }
            },
          )
          .subscribe();

      AppLogger.info('Stock changes subscription initialized');
    } catch (e) {
      AppLogger.error('Error subscribing to stock changes', error: e);
    }
  }

  // Create stock alert notification
  Future<void> _createStockAlert(Map<String, dynamic> stockData) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('notifications').insert({
        'user_id': user.id,
        'title': 'Low Stock Alert',
        'message':
            'Product ${stockData['product_id']} is running low (${stockData['current_level']} remaining)',
        'type': 'stock_alert',
        'data': {
          'product_id': stockData['product_id'],
          'current_level': stockData['current_level'],
          'minimum_level': stockData['minimum_level'],
        },
      });

      AppLogger.info('Stock alert notification created');
    } catch (e) {
      AppLogger.error('Error creating stock alert', error: e);
    }
  }

  // Clean up subscriptions
  @override
  void dispose() {
    _notificationChannel?.unsubscribe();
    _isSubscriptionActive = false;
    super.dispose();
  }
}