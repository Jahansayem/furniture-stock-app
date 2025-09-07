import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../constants/onesignal_config.dart';
import '../models/sale.dart';
import '../services/onesignal_service.dart';
import '../services/steadfast_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/offline_storage_service.dart';
import '../utils/logger.dart';

class SalesProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivity = ConnectivityService();
  final SteadFastService _courierService = SteadFastService();

  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> fetchSales() async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _supabase.from(SupabaseConfig.salesTable).select('''
            *,
            products:product_id(product_name, price),
            stock_locations:location_id(location_name)
          ''').order('sale_date', ascending: false);

      _sales = (response as List).map((json) {
        // Flatten the response to include product and location names
        final flatJson = Map<String, dynamic>.from(json);
        if (json['products'] != null) {
          flatJson['product_name'] = json['products']['product_name'];
        }
        if (json['stock_locations'] != null) {
          flatJson['location_name'] = json['stock_locations']['location_name'];
        }
        return Sale.fromJson(flatJson);
      }).toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch sales: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createSale({
    required String productId,
    required String locationId,
    required int quantity,
    required double unitPrice,
    required String saleType, // 'online_cod' or 'offline'
    required String customerName,
    String? customerPhone,
    String? customerAddress,
    String? notes,
    // Courier fields for online COD
    String? deliveryType,
    String? recipientName,
    String? recipientPhone,
    String? recipientAddress,
    double? codAmount,
    String? courierNotes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return false;
      }

      // Validate unit price
      if (unitPrice <= 0) {
        _setError('Unit price must be greater than 0');
        _setLoading(false);
        return false;
      }

      final totalAmount = unitPrice * quantity;

      // If offline, store sale locally and add as pending action
      if (!_connectivity.isOnline) {
        final saleData = {
          'product_id': productId,
          'product_name': 'Unknown Product', // Will be updated when synced
          'location_id': locationId,
          'location_name': 'Unknown Location', // Will be updated when synced
          'quantity': quantity,
          'unit_price': unitPrice,
          'total_amount': totalAmount,
          'sale_type': saleType,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'customer_address': customerAddress,
          'sold_by': user.id,
          'sold_by_name': user.email ?? 'Unknown User',
          'sale_date': DateTime.now().toIso8601String(),
          'status': 'completed',
          'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
        };

        // Add to pending actions for sync
        await SyncService.addPendingAction('create_sale', saleData);

        // Add to local sales list
        _sales.insert(
            0,
            Sale.fromJson({
              ...saleData,
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
            }));

        _setLoading(false);
        notifyListeners();
        return true;
      }

      // Online: perform normal operation
      // Get user profile for display name
      final profileResponse = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('full_name')
          .eq('id', user.id)
          .single();

      final userName =
          profileResponse['full_name'] ?? user.email ?? 'Unknown User';

      // Get product details
      final productResponse = await _supabase
          .from(SupabaseConfig.productsTable)
          .select('product_name, price')
          .eq('id', productId)
          .single();

      final productName = productResponse['product_name'];
      final fallbackPrice = (productResponse['price'] ?? 0).toDouble();
      final productPrice = unitPrice > 0
          ? unitPrice
          : (fallbackPrice > 0 ? fallbackPrice : throw Exception('Product price must be greater than 0. Please update the product price or provide a valid unit price.'));

      // Get location details
      final locationResponse = await _supabase
          .from(SupabaseConfig.stockLocationsTable)
          .select('location_name')
          .eq('id', locationId)
          .single();

      final locationName = locationResponse['location_name'];

      // Check stock availability
      final stockResponse = await _supabase
          .from(SupabaseConfig.stockLevelsTable)
          .select('quantity')
          .eq('product_id', productId)
          .eq('location_id', locationId)
          .maybeSingle();

      final currentStock = stockResponse?['quantity'] ?? 0;
      if (currentStock < quantity) {
        _setError(
            'Insufficient stock. Available: $currentStock, Required: $quantity');
        _setLoading(false);
        return false;
      }

      // Create sale record with courier fields
      final saleId = const Uuid().v4();
      final orderStatus = saleType == 'online_cod' ? 'pending' : 'completed';
      final saleData = {
        'id': saleId,
        'product_id': productId,
        'product_name': productName,
        'location_id': locationId,
        'location_name': locationName,
        'quantity': quantity,
        'unit_price': productPrice,
        'total_amount': totalAmount,
        'sale_type': saleType,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'sold_by': user.id,
        'sold_by_name': userName,
        'sale_date': DateTime.now().toIso8601String(),
        'status': orderStatus,
        'notes': notes,
        // Courier fields
        'delivery_type': deliveryType,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'recipient_address': recipientAddress,
        'cod_amount': codAmount,
        'courier_notes': courierNotes,
      };

      await _supabase.from(SupabaseConfig.salesTable).insert(saleData);

      // Record stock movement for sale
      await _supabase.from(SupabaseConfig.stockMovementsTable).insert({
        'product_id': productId,
        'from_location_id': locationId,
        'quantity': quantity,
        'movement_type': 'sale',
        'notes': 'Sale to $customerName ($saleType) by $userName',
      });

      // Update stock quantity (reduce)
      await _updateStockQuantity(productId, locationId, -quantity);

      // Send notification to all users about new sale
      try {
        AppLogger.debug('Attempting to send sale notification');
        AppLogger.info('Sale details: $quantity units of $productName to $customerName for ৳${totalAmount.toStringAsFixed(2)}');

        // First, ensure OneSignal is initialized
        if (!OneSignalService.isInitialized) {
          AppLogger.warning('OneSignal not initialized, attempting to initialize');
          await OneSignalService.initialize();
        }

        // Check if we have a current player ID
        final currentPlayerId = OneSignalService.playerId;
        if (currentPlayerId == null) {
          AppLogger.warning('No OneSignal Player ID available for current user');
        } else {
          AppLogger.debug('Current user OneSignal Player ID: ${currentPlayerId.substring(0, 20)}...');
        }

        final notificationResult = await OneSignalService.sendNotificationToAll(
          title: '💰 New Sale Created',
          message:
              '$quantity units of $productName sold to $customerName for ৳${totalAmount.toStringAsFixed(2)}',
          data: {
            'type': 'sale',
            'product_id': productId,
            'location_id': locationId,
            'quantity': quantity,
            'customer_name': customerName,
            'total_amount': totalAmount,
            'sold_by': userName,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (notificationResult) {
          AppLogger.info('Sale notification sent successfully');
        } else {
          AppLogger.warning('Sale notification failed to send');

          // OneSignal notification failed
        }
      } catch (e) {
        // Don't fail the operation if notification fails
        AppLogger.error('Failed to send sale notification', error: e);
      }

      // Refresh sales data
      await fetchSales();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create sale: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> _updateStockQuantity(
      String productId, String locationId, int quantityChange) async {
    // Get existing stock
    final existingStockResponse = await _supabase
        .from(SupabaseConfig.stockLevelsTable)
        .select()
        .eq('product_id', productId)
        .eq('location_id', locationId)
        .maybeSingle();

    final currentQuantity = existingStockResponse?['quantity'] ?? 0;
    final newQuantity = currentQuantity + quantityChange;

    if (existingStockResponse == null) {
      // Create new stock entry
      await _supabase.from(SupabaseConfig.stockLevelsTable).insert({
        'product_id': productId,
        'location_id': locationId,
        'quantity': newQuantity,
      });
    } else {
      // Update existing stock entry
      await _supabase.from(SupabaseConfig.stockLevelsTable).update(
          {'quantity': newQuantity}).eq('id', existingStockResponse['id']);
    }
  }

  Future<List<Sale>> getRecentSales({int limit = 10}) async {
    try {
      final response =
          await _supabase.from(SupabaseConfig.salesTable).select('''
            *,
            products:product_id(product_name),
            stock_locations:location_id(location_name)
          ''').order('sale_date', ascending: false).limit(limit);

      return (response as List).map((json) {
        final flatJson = Map<String, dynamic>.from(json);
        if (json['products'] != null) {
          flatJson['product_name'] = json['products']['product_name'];
        }
        if (json['stock_locations'] != null) {
          flatJson['location_name'] = json['stock_locations']['location_name'];
        }
        return Sale.fromJson(flatJson);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  double getTotalSalesAmount({DateTime? startDate, DateTime? endDate}) {
    var filteredSales = _sales.where((sale) => sale.status == 'completed');

    if (startDate != null) {
      filteredSales =
          filteredSales.where((sale) => sale.saleDate.isAfter(startDate));
    }

    if (endDate != null) {
      filteredSales =
          filteredSales.where((sale) => sale.saleDate.isBefore(endDate));
    }

    return filteredSales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  int getTotalSalesQuantity({DateTime? startDate, DateTime? endDate}) {
    var filteredSales = _sales.where((sale) => sale.status == 'completed');

    if (startDate != null) {
      filteredSales =
          filteredSales.where((sale) => sale.saleDate.isAfter(startDate));
    }

    if (endDate != null) {
      filteredSales =
          filteredSales.where((sale) => sale.saleDate.isBefore(endDate));
    }

    return filteredSales.fold(0, (sum, sale) => sum + sale.quantity);
  }

  // Courier Integration Methods


  /// Update courier status for a sale
  Future<bool> updateCourierStatus({
    String? saleId,
    String? consignmentId,
    String? invoice,
    String? trackingCode,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('Checking courier status for sale: $saleId');

      final statusResponse = await _courierService.checkStatus(
        consignmentId: consignmentId,
        invoice: invoice,
        trackingCode: trackingCode,
      );

      if (statusResponse != null && statusResponse.success) {
        final updateData = {
          'courier_status': statusResponse.status ?? 'unknown',
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (statusResponse.deliveryDate != null) {
          updateData['delivery_date'] = statusResponse.deliveryDate!;
        }

        // Update the sale record
        if (saleId != null) {
          await _supabase.from(SupabaseConfig.salesTable)
              .update(updateData)
              .eq('id', saleId);
        } else if (consignmentId != null) {
          await _supabase.from(SupabaseConfig.salesTable)
              .update(updateData)
              .eq('consignment_id', consignmentId);
        }

        // Update local sales list
        await fetchSales();

        AppLogger.info('Courier status updated: ${statusResponse.status}');
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to check courier status: ${statusResponse?.message ?? 'Unknown error'}');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      AppLogger.error('Exception updating courier status', error: e);
      _setError('Error updating courier status: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Get sales with courier orders (online COD)
  List<Sale> getCourierOrders() {
    return _sales.where((sale) => 
      sale.saleType == 'online_cod' && sale.consignmentId != null
    ).toList();
  }

  /// Get pending courier deliveries
  List<Sale> getPendingDeliveries() {
    return _sales.where((sale) => 
      sale.saleType == 'online_cod' && 
      sale.consignmentId != null &&
      sale.courierStatus != 'delivered' &&
      sale.courierStatus != 'returned' &&
      sale.courierStatus != 'cancelled'
    ).toList();
  }

  /// Bulk update courier status for all pending orders
  Future<void> refreshAllCourierStatuses() async {
    final pendingOrders = getPendingDeliveries();
    
    AppLogger.info('Refreshing status for ${pendingOrders.length} pending courier orders');

    for (final sale in pendingOrders) {
      if (sale.consignmentId != null) {
        await updateCourierStatus(
          saleId: sale.id,
          consignmentId: sale.consignmentId,
        );
        
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    AppLogger.info('Completed refreshing courier statuses');
  }

  /// Send a pending order to Steadfast courier
  Future<bool> sendOrderToCourier(String saleId) async {
    _setLoading(true);
    _clearError();

    try {
      // Get the sale details
      final sale = _sales.firstWhere((s) => s.id == saleId);
      
      // Validate that this is a pending online COD order
      if (sale.saleType != 'online_cod') {
        _setError('Only online COD orders can be sent to courier');
        _setLoading(false);
        return false;
      }

      if (sale.status != 'pending') {
        _setError('Order is not in pending status');
        _setLoading(false);
        return false;
      }

      if (sale.recipientName == null || sale.recipientPhone == null || 
          sale.recipientAddress == null || sale.codAmount == null) {
        _setError('Missing required courier information');
        _setLoading(false);
        return false;
      }

      // Create courier order
      final response = await _courierService.createOrder(
        invoice: saleId,
        recipientName: sale.recipientName!,
        recipientPhone: sale.recipientPhone!,
        recipientAddress: sale.recipientAddress!,
        codAmount: sale.codAmount!,
        notes: sale.courierNotes,
      );

      if (response != null && response.success) {
        // Update the sale record with courier information
        await _supabase.from(SupabaseConfig.salesTable)
            .update({
              'consignment_id': response.consignmentId,
              'tracking_code': response.trackingCode,
              'courier_status': 'pending', // Use valid Steadfast API status
              'status': 'completed', // Mark as completed since it's sent to courier
              'courier_created_at': DateTime.now().toIso8601String(),
            })
            .eq('id', saleId);

        // Refresh sales data
        await fetchSales();

        AppLogger.info('Order sent to courier successfully: ${response.consignmentId}');
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to send order to courier: ${response?.message ?? 'Unknown error'}');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      AppLogger.error('Exception sending order to courier', error: e);
      _setError('Error sending order to courier: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Get all pending orders (not yet sent to courier)
  List<Sale> getPendingOrders() {
    return _sales.where((sale) => 
      sale.saleType == 'online_cod' && sale.status == 'pending'
    ).toList();
  }

  /// Get orders by status
  List<Sale> getOrdersByStatus(String status) {
    return _sales.where((sale) => 
      sale.saleType == 'online_cod' && sale.status == status
    ).toList();
  }

  /// Cancel a pending order
  Future<bool> cancelOrder(String saleId, String cancelReason) async {
    _setLoading(true);
    _clearError();

    try {
      // Get the sale details
      final sale = _sales.firstWhere((s) => s.id == saleId);
      
      // Validate that this is a pending order that can be cancelled
      if (sale.saleType != 'online_cod') {
        _setError('Only online COD orders can be cancelled');
        _setLoading(false);
        return false;
      }

      if (sale.status != 'pending') {
        _setError('Order is not in pending status and cannot be cancelled');
        _setLoading(false);
        return false;
      }

      // If order has been sent to courier, we cannot cancel it here
      if (sale.consignmentId != null && sale.consignmentId!.isNotEmpty) {
        _setError('Order has been sent to courier and cannot be cancelled here. Contact courier service.');
        _setLoading(false);
        return false;
      }

      // Update the sale record status to cancelled
      await _supabase.from(SupabaseConfig.salesTable)
          .update({
            'status': 'cancelled',
            'cancel_reason': cancelReason,
            'updated_at': DateTime.now().toIso8601String(),
            'notes': sale.notes != null 
                ? '${sale.notes}\n[CANCELLED] Order cancelled by user on ${DateTime.now().toString()}'
                : '[CANCELLED] Order cancelled by user on ${DateTime.now().toString()}',
          })
          .eq('id', saleId);

      // Restore stock quantity since the sale is cancelled
      await _updateStockQuantity(sale.productId, sale.locationId, sale.quantity);

      // Record stock movement for cancellation
      final user = _supabase.auth.currentUser;
      final userName = user?.email ?? 'Unknown User';
      
      await _supabase.from(SupabaseConfig.stockMovementsTable).insert({
        'id': const Uuid().v4(),
        'product_id': sale.productId,
        'to_location_id': sale.locationId,
        'quantity': sale.quantity,
        'movement_type': 'adjustment',
        'notes': 'Stock restored due to order cancellation for ${sale.customerName} by $userName - Cancel reason: $cancelReason',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Send notification about cancelled order
      try {
        AppLogger.debug('Attempting to send order cancellation notification');
        
        final notificationResult = await OneSignalService.sendNotificationToAll(
          title: '❌ Order Cancelled',
          message: 'Order for ${sale.quantity}x ${sale.productName} by ${sale.customerName} has been cancelled',
          data: {
            'type': 'order_cancelled',
            'sale_id': saleId,
            'product_id': sale.productId,
            'location_id': sale.locationId,
            'quantity': sale.quantity,
            'customer_name': sale.customerName,
            'total_amount': sale.totalAmount,
            'cancelled_by': userName,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (notificationResult) {
          AppLogger.info('Order cancellation notification sent successfully');
        } else {
          AppLogger.warning('Order cancellation notification failed to send');
        }
      } catch (e) {
        // Don't fail the operation if notification fails
        AppLogger.error('Failed to send order cancellation notification', error: e);
      }

      // Refresh sales data
      await fetchSales();

      AppLogger.info('Order cancelled successfully: $saleId');
      _setLoading(false);
      return true;
    } catch (e) {
      AppLogger.error('Exception cancelling order', error: e);
      _setError('Error cancelling order: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update a pending order
  Future<bool> updatePendingOrder({
    required String orderId,
    required String customerName,
    String? customerPhone,
    String? customerAddress,
    required String recipientName,
    required String recipientPhone,
    required String recipientAddress,
    required String deliveryType,
    required double codAmount,
    String? courierNotes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Get the current sale details
      final sale = _sales.firstWhere((s) => s.id == orderId);
      
      // Validate that this is a pending order that can be edited
      if (sale.saleType != 'online_cod') {
        _setError('Only online COD orders can be edited');
        _setLoading(false);
        return false;
      }

      if (sale.status != 'pending') {
        _setError('Order is not in pending status and cannot be edited');
        _setLoading(false);
        return false;
      }

      // If order has been sent to courier, we cannot edit it
      if (sale.consignmentId != null && 
          sale.consignmentId!.isNotEmpty && 
          sale.consignmentId != 'PENDING_OFFLINE') {
        _setError('Order has been sent to courier and cannot be edited. Contact courier service.');
        _setLoading(false);
        return false;
      }

      // Validate phone number format
      if (!RegExp(r'^\d{11}$').hasMatch(recipientPhone)) {
        _setError('Recipient phone must be exactly 11 digits');
        _setLoading(false);
        return false;
      }

      // Validate required fields
      if (recipientName.trim().isEmpty || 
          recipientPhone.trim().isEmpty || 
          recipientAddress.trim().isEmpty) {
        _setError('All recipient details are required');
        _setLoading(false);
        return false;
      }

      if (codAmount <= 0) {
        _setError('COD amount must be greater than 0');
        _setLoading(false);
        return false;
      }

      // Prepare update data
      final updateData = {
        'customer_name': customerName.trim(),
        'customer_phone': customerPhone?.trim(),
        'customer_address': customerAddress?.trim(),
        'recipient_name': recipientName.trim(),
        'recipient_phone': recipientPhone.trim(),
        'recipient_address': recipientAddress.trim(),
        'delivery_type': deliveryType,
        'cod_amount': codAmount,
        'courier_notes': courierNotes?.trim(),
      };

      // Update the sale record in the database
      await _supabase.from(SupabaseConfig.salesTable)
          .update(updateData)
          .eq('id', orderId);

      // Refresh sales data to show updated information
      await fetchSales();

      AppLogger.info('Order updated successfully: $orderId');
      
      // Try to send notification about order update
      try {
        await sendOneSignalNotificationToAllUsers(
          appId: OneSignalConfig.appId,
          restApiKey: OneSignalConfig.restApiKey,
          title: '📝 অর্ডার আপডেট করা হয়েছে',
          message: 'Order updated for $customerName - $recipientName (${sale.productName})',
        );
      } catch (e) {
        // Don't fail the operation if notification fails
        AppLogger.error('Failed to send order update notification', error: e);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      AppLogger.error('Exception updating order', error: e);
      _setError('Error updating order: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
}
