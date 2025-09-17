import 'dart:async';
import 'dart:convert';
import 'dart:math' show atan2, cos, sin, sqrt, pi;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

/// Comprehensive backend integration service for FurniShop Manager
/// Handles all external API integrations and real-time subscriptions
class BackendIntegrationService {
  static final BackendIntegrationService _instance = BackendIntegrationService._internal();
  factory BackendIntegrationService() => _instance;
  BackendIntegrationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, Function> _callbacks = {};

  // ==========================================
  // REAL-TIME SUBSCRIPTION MANAGEMENT
  // ==========================================

  /// Initialize real-time subscriptions for user role
  Future<void> initializeSubscriptions(String userId, String userRole, String? warehouseId) async {
    try {
      await _clearExistingSubscriptions();

      // Subscribe based on user role and permissions
      if (['owner', 'admin'].contains(userRole)) {
        await _subscribeToAllData(userId);
      } else if (['manager', 'sales_executive'].contains(userRole) && warehouseId != null) {
        await _subscribeToWarehouseData(userId, warehouseId);
      } else {
        await _subscribeToUserSpecificData(userId);
      }

      debugPrint('✅ Real-time subscriptions initialized for role: $userRole');
    } catch (e) {
      debugPrint('❌ Failed to initialize subscriptions: $e');
    }
  }

  /// Subscribe to all data (owner/admin)
  Future<void> _subscribeToAllData(String userId) async {
    // Orders subscription
    _subscriptions['orders'] = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .listen((data) => _handleOrderUpdate(data));

    // Stock alerts subscription
    _subscriptions['stocks'] = _supabase
        .from('stocks')
        .stream(primaryKey: ['id'])
        .listen((data) => _handleStockUpdate(data));

    // Attendance monitoring
    _subscriptions['attendance'] = _supabase
        .from('attendance_records')
        .stream(primaryKey: ['id'])
        .listen((data) => _handleAttendanceUpdate(data));

    // Financial transactions
    _subscriptions['transactions'] = _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .listen((data) => _handleTransactionUpdate(data));

    // Material requests
    _subscriptions['material_requests'] = _supabase
        .from('material_requests')
        .stream(primaryKey: ['id'])
        .listen((data) => _handleMaterialRequestUpdate(data));

    // System notifications
    _subscriptions['notifications'] = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) => _handleNotificationUpdate(data));
  }

  /// Subscribe to warehouse-specific data (manager/sales)
  Future<void> _subscribeToWarehouseData(String userId, String warehouseId) async {
    // Orders for specific warehouse
    _subscriptions['orders'] = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('warehouse_id', warehouseId)
        .listen((data) => _handleOrderUpdate(data));

    // Stock for warehouse
    _subscriptions['stocks'] = _supabase
        .from('stocks')
        .stream(primaryKey: ['id'])
        .listen((data) => _handleStockUpdate(data, warehouseId: warehouseId));

    // Employee attendance for warehouse
    _subscriptions['attendance'] = _supabase
        .from('attendance_records')
        .stream(primaryKey: ['id'])
        .listen((data) => _handleAttendanceUpdate(data, warehouseId: warehouseId));

    // User notifications
    _subscriptions['notifications'] = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .or('user_id.eq.$userId,warehouse_id.eq.$warehouseId')
        .listen((data) => _handleNotificationUpdate(data));
  }

  /// Subscribe to user-specific data only
  Future<void> _subscribeToUserSpecificData(String userId) async {
    // Own notifications
    _subscriptions['notifications'] = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) => _handleNotificationUpdate(data));

    // Own orders (if sales person)
    _subscriptions['orders'] = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('sales_person_id', userId)
        .listen((data) => _handleOrderUpdate(data));
  }

  /// Clear existing subscriptions
  Future<void> _clearExistingSubscriptions() async {
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  // ==========================================
  // REAL-TIME DATA HANDLERS
  // ==========================================

  void _handleOrderUpdate(List<Map<String, dynamic>> data) {
    for (final order in data) {
      _triggerCallback('order_updated', order);
      
      // Send notifications based on status changes
      if (order['order_status'] == 'delivered') {
        _createNotification(
          order['sales_person_id'],
          'Order Delivered',
          'Order ${order['order_number']} has been delivered successfully',
          type: 'success',
          category: 'order'
        );
      } else if (order['order_status'] == 'cancelled') {
        _createNotification(
          order['sales_person_id'],
          'Order Cancelled',
          'Order ${order['order_number']} has been cancelled',
          type: 'warning',
          category: 'order'
        );
      }
    }
  }

  void _handleStockUpdate(List<Map<String, dynamic>> data, {String? warehouseId}) {
    for (final stock in data) {
      _triggerCallback('stock_updated', stock);

      // Check for low stock alerts
      if (stock['quantity'] != null) {
        _checkLowStockAlert(stock);
      }
    }
  }

  void _handleAttendanceUpdate(List<Map<String, dynamic>> data, {String? warehouseId}) {
    for (final attendance in data) {
      _triggerCallback('attendance_updated', attendance);

      // Alert for invalid GPS locations
      if (attendance['is_valid_location'] == false) {
        _createSystemAlert(
          'Invalid Check-in Location',
          'Employee checked in from unauthorized location',
          priority: 'high',
          category: 'attendance'
        );
      }
    }
  }

  void _handleTransactionUpdate(List<Map<String, dynamic>> data) {
    for (final transaction in data) {
      _triggerCallback('transaction_updated', transaction);
    }
  }

  void _handleMaterialRequestUpdate(List<Map<String, dynamic>> data) {
    for (final request in data) {
      _triggerCallback('material_request_updated', request);

      if (request['status'] == 'pending') {
        _createNotification(
          null, // System notification
          'Material Request Pending',
          'New material request requires approval',
          type: 'info',
          category: 'production'
        );
      }
    }
  }

  void _handleNotificationUpdate(List<Map<String, dynamic>> data) {
    for (final notification in data) {
      _triggerCallback('notification_received', notification);
    }
  }

  // ==========================================
  // CALLBACK MANAGEMENT
  // ==========================================

  void registerCallback(String event, Function callback) {
    _callbacks[event] = callback;
  }

  void unregisterCallback(String event) {
    _callbacks.remove(event);
  }

  void _triggerCallback(String event, dynamic data) {
    if (_callbacks.containsKey(event)) {
      try {
        _callbacks[event]!(data);
      } catch (e) {
        debugPrint('❌ Callback error for $event: $e');
      }
    }
  }

  // ==========================================
  // STEADFAST COURIER API INTEGRATION
  // ==========================================

  /// Create shipment with Steadfast Courier
  Future<Map<String, dynamic>?> createSteadfastShipment({
    required String orderId,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      const String apiUrl = 'https://portal.steadfast.com.bd/api/v1/create_order';
      const String apiKey = 'YOUR_STEADFAST_API_KEY'; // From environment
      const String secretKey = 'YOUR_STEADFAST_SECRET_KEY';

      final shipmentData = {
        'invoice': orderData['order_number'],
        'recipient_name': orderData['customer_name'],
        'recipient_phone': orderData['customer_phone'],
        'recipient_address': orderData['customer_address'],
        'cod_amount': orderData['total_amount'],
        'note': orderData['notes'] ?? '',
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Api-Key': apiKey,
          'Secret-Key': secretKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(shipmentData),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // Update order with tracking info
        await _supabase.from('orders').update({
          'consignment_id': result['consignment_id'],
          'tracking_code': result['tracking_code'],
          'order_status': 'shipped',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);

        return result;
      } else {
        debugPrint('❌ Steadfast API error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Steadfast integration error: $e');
      return null;
    }
  }

  /// Track shipment status
  Future<Map<String, dynamic>?> trackSteadfastShipment(String consignmentId) async {
    try {
      const String apiUrl = 'https://portal.steadfast.com.bd/api/v1/status_by_cid';
      const String apiKey = 'YOUR_STEADFAST_API_KEY';
      const String secretKey = 'YOUR_STEADFAST_SECRET_KEY';

      final response = await http.get(
        Uri.parse('$apiUrl/$consignmentId'),
        headers: {
          'Api-Key': apiKey,
          'Secret-Key': secretKey,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('❌ Tracking API error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Tracking error: $e');
      return null;
    }
  }

  // ==========================================
  // SMS SERVICE INTEGRATION
  // ==========================================

  /// Send SMS notification
  Future<bool> sendSMS({
    required String phoneNumber,
    required String message,
    String? templateId,
  }) async {
    try {
      const String apiUrl = 'https://api.sms.com.bd/send'; // Your SMS provider
      const String apiKey = 'YOUR_SMS_API_KEY';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'to': phoneNumber,
          'message': message,
          'template_id': templateId,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ SMS sent successfully to $phoneNumber');
        return true;
      } else {
        debugPrint('❌ SMS API error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ SMS sending error: $e');
      return false;
    }
  }

  // ==========================================
  // PDF GENERATION SERVICE
  // ==========================================

  /// Generate invoice PDF
  Future<String?> generateInvoicePDF(String orderId) async {
    try {
      // This would integrate with a PDF generation service
      // For now, return a mock URL
      return 'https://your-domain.com/invoices/$orderId.pdf';
    } catch (e) {
      debugPrint('❌ PDF generation error: $e');
      return null;
    }
  }

  // ==========================================
  // GPS VALIDATION SERVICE
  // ==========================================

  /// Validate GPS coordinates against allowed locations
  Future<bool> validateGPSLocation(
    double latitude,
    double longitude,
    String employeeId,
  ) async {
    try {
      // Get allowed locations for employee
      final response = await _supabase
          .from('employees')
          .select('allowed_locations')
          .eq('id', employeeId)
          .single();

      if (response['allowed_locations'] == null) return true;

      final allowedLocations = List<Map<String, dynamic>>.from(
        response['allowed_locations'] as List
      );

      for (final location in allowedLocations) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          location['lat'],
          location['lng'],
        );

        if (distance <= location['radius']) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ GPS validation error: $e');
      return true; // Allow if validation fails
    }
  }

  /// Calculate distance between two GPS coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // ==========================================
  // NOTIFICATION HELPERS
  // ==========================================

  /// Create system notification
  Future<void> _createNotification(
    String? userId,
    String title,
    String message, {
    String type = 'info',
    String category = 'general',
    String priority = 'normal',
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'category': category,
        'priority': priority,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Failed to create notification: $e');
    }
  }

  /// Create system alert for administrators
  Future<void> _createSystemAlert(
    String title,
    String message, {
    String priority = 'normal',
    String category = 'system',
  }) async {
    try {
      // Get all admin/owner users
      final admins = await _supabase
          .from('user_profiles')
          .select('id')
          .in_('role', ['owner', 'admin']);

      for (final admin in admins) {
        await _createNotification(
          admin['id'],
          title,
          message,
          type: 'warning',
          category: category,
          priority: priority,
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to create system alert: $e');
    }
  }

  /// Check for low stock alerts
  Future<void> _checkLowStockAlert(Map<String, dynamic> stock) async {
    try {
      // Get product details
      final product = await _supabase
          .from('products')
          .select('product_name, low_stock_threshold')
          .eq('id', stock['product_id'])
          .single();

      if (stock['quantity'] <= product['low_stock_threshold']) {
        await _createSystemAlert(
          'Low Stock Alert',
          'Product "${product['product_name']}" is running low (${stock['quantity']} remaining)',
          priority: 'high',
          category: 'stock',
        );
      }
    } catch (e) {
      debugPrint('❌ Stock alert error: $e');
    }
  }

  // ==========================================
  // BULK OPERATIONS AND SYNC
  // ==========================================

  /// Bulk update stock levels
  Future<bool> bulkUpdateStock(List<Map<String, dynamic>> updates) async {
    try {
      await _supabase.from('stocks').upsert(updates);
      return true;
    } catch (e) {
      debugPrint('❌ Bulk stock update error: $e');
      return false;
    }
  }

  /// Sync offline data
  Future<bool> syncOfflineData(List<Map<String, dynamic>> offlineActions) async {
    try {
      for (final action in offlineActions) {
        switch (action['type']) {
          case 'create_order':
            await _supabase.from('orders').insert(action['data']);
            break;
          case 'update_stock':
            await _supabase.from('stocks').update(action['data']).eq('id', action['id']);
            break;
          case 'attendance':
            await _supabase.from('attendance_records').insert(action['data']);
            break;
          default:
            debugPrint('⚠️ Unknown sync action type: ${action['type']}');
        }
      }
      return true;
    } catch (e) {
      debugPrint('❌ Offline sync error: $e');
      return false;
    }
  }

  // ==========================================
  // CLEANUP AND DISPOSAL
  // ==========================================

  /// Dispose all subscriptions and cleanup
  Future<void> dispose() async {
    await _clearExistingSubscriptions();
    _callbacks.clear();
    debugPrint('✅ Backend integration service disposed');
  }
}