import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
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
        'status': 'completed',
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

      // For online COD orders, create courier order
      if (saleType == 'online_cod' && recipientName != null && recipientPhone != null && recipientAddress != null && codAmount != null) {
        AppLogger.info('Creating courier order for sale: $saleId');
        await _createCourierOrder(
          saleId: saleId,
          recipientName: recipientName,
          recipientPhone: recipientPhone,
          recipientAddress: recipientAddress,
          codAmount: codAmount,
          notes: courierNotes,
        );
      }

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

  /// Create courier order for online COD sales
  Future<void> _createCourierOrder({
    required String saleId,
    required String recipientName,
    required String recipientPhone,
    required String recipientAddress,
    required double codAmount,
    String? notes,
  }) async {
    try {
      AppLogger.info('Creating Steadfast courier order for sale: $saleId');

      final response = await _courierService.createOrder(
        invoice: saleId, // Use sale ID as invoice number
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        recipientAddress: recipientAddress,
        codAmount: codAmount,
        notes: notes,
      );

      if (response != null && response.success) {
        AppLogger.info('Courier order created successfully: ${response.consignmentId}');
        
        // Update the sale record with courier information
        await _supabase.from(SupabaseConfig.salesTable)
            .update({
              'consignment_id': response.consignmentId,
              'tracking_code': response.trackingCode,
              'courier_status': 'pending',
              'courier_created_at': DateTime.now().toIso8601String(),
            })
            .eq('id', saleId);

        AppLogger.info('Sale updated with courier details');
      } else {
        AppLogger.error('Failed to create courier order: ${response?.message ?? 'Unknown error'}');
        
        // Update sale record to indicate courier order failure
        await _supabase.from(SupabaseConfig.salesTable)
            .update({
              'courier_status': 'failed',
              'courier_notes': 'Courier order creation failed: ${response?.message ?? 'Unknown error'}',
            })
            .eq('id', saleId);
      }
    } catch (e) {
      AppLogger.error('Exception creating courier order', error: e);
      
      // Update sale record to indicate courier order exception
      await _supabase.from(SupabaseConfig.salesTable)
          .update({
            'courier_status': 'failed',
            'courier_notes': 'Courier order exception: ${e.toString()}',
          })
          .eq('id', saleId);
    }
  }

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
}
