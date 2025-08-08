import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/sale.dart';
import '../services/onesignal_service.dart';

import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

class SalesProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivity = ConnectivityService();

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
      final productPrice = unitPrice > 0
          ? unitPrice
          : (productResponse['price'] ?? 0).toDouble();

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

      // Create sale record
      await _supabase.from(SupabaseConfig.salesTable).insert({
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
      });

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
        print('🔔 Attempting to send sale notification...');
        print(
            '📊 Sale details: $quantity units of $productName to $customerName for ৳${totalAmount.toStringAsFixed(2)}');

        // First, ensure OneSignal is initialized
        if (!OneSignalService.isInitialized) {
          print('⚠️ OneSignal not initialized, attempting to initialize...');
          await OneSignalService.initialize();
        }

        // Check if we have a current player ID
        final currentPlayerId = OneSignalService.playerId;
        if (currentPlayerId == null) {
          print('⚠️ No OneSignal Player ID available for current user');
        } else {
          print(
              '✅ Current user OneSignal Player ID: ${currentPlayerId.substring(0, 20)}...');
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
          print('✅ Sale notification sent successfully');
        } else {
          print('❌ Sale notification failed to send');

          // OneSignal notification failed
        }
      } catch (e) {
        // Don't fail the operation if notification fails
        print('❌ Failed to send sale notification: $e');
        print('📋 Error details: ${e.toString()}');
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
}
