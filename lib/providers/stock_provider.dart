import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/stock.dart';
import '../services/onesignal_service.dart';
import '../services/offline_storage_service.dart';
import '../utils/logger.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

class StockProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivity = ConnectivityService();

  bool _isLoading = false;
  String? _errorMessage;
  List<Stock> _stocks = [];
  List<StockLocation> _locations = [];
  List<StockMovement> _movements = [];
  bool _isShowingOfflineData = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Stock> get stocks => _stocks;
  List<StockLocation> get locations => _getFilteredLocations();
  List<StockLocation> get allLocations =>
      _locations; // Original unfiltered locations
  List<StockMovement> get movements => _movements;
  bool get isShowingOfflineData => _isShowingOfflineData;

  // Filter locations to only show specific allowed ones
  List<StockLocation> _getFilteredLocations() {
    final allowedLocationNames = [
      'Showroom Display',
      'Factory',
      'Warehouse',
    ];

    final excludedLocationNames = [
      'Main Factory',
      'Showroom 1',
    ];

    return _locations.where((location) {
      // First check if it's in the excluded list
      if (excludedLocationNames.any((excluded) => location.locationName
          .toLowerCase()
          .contains(excluded.toLowerCase()))) {
        return false;
      }

      // Then check if it's in the allowed list
      return allowedLocationNames.contains(location.locationName) ||
          allowedLocationNames.any((allowed) => location.locationName
              .toLowerCase()
              .contains(allowed.toLowerCase()));
    }).toList();
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
    notifyListeners();
  }

  // Get total stock count for factory
  int get factoryStockCount {
    return _stocks
        .where((stock) =>
            _getLocationById(stock.locationId)?.locationType == 'factory')
        .fold(0, (sum, stock) => sum + stock.quantity);
  }

  // Get total stock count for showroom
  int get showroomStockCount {
    return _stocks
        .where((stock) =>
            _getLocationById(stock.locationId)?.locationType == 'showroom')
        .fold(0, (sum, stock) => sum + stock.quantity);
  }

  // Get low stock items count
  int getLowStockCount(List<dynamic> products) {
    int lowStockCount = 0;
    for (var product in products) {
      final productStocks =
          _stocks.where((stock) => stock.productId == product.id);
      final totalQuantity =
          productStocks.fold(0, (sum, stock) => sum + stock.quantity);
      if (totalQuantity <= product.lowStockThreshold) {
        lowStockCount++;
      }
    }
    return lowStockCount;
  }

  StockLocation? _getLocationById(String locationId) {
    try {
      return _locations.firstWhere((location) => location.id == locationId);
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchStocks() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase
          .from(SupabaseConfig.stockLevelsTable)
          .select()
          .order('updated_at', ascending: false);

      _stocks = (response as List).map((json) => Stock.fromJson(json)).toList();
    } catch (e) {
      _setError('Failed to fetch stocks: ${e.toString()}');
    }

    _setLoading(false);
  }

  Future<void> fetchLocations() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.stockLocationsTable)
          .select()
          .order('location_name');

      _locations = (response as List)
          .map((json) => StockLocation.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch locations: ${e.toString()}');
    }
  }

  Future<void> fetchMovements() async {
    // Check if offline
    if (!_connectivity.isOnline) {
      _loadOfflineMovements();
      return;
    }

    try {
      final response =
          await _supabase.from(SupabaseConfig.stockMovementsTable).select('''
            *,
            products!inner(product_name),
            from_location:from_location_id(location_name),
            to_location:to_location_id(location_name)
          ''').order('created_at', ascending: false).limit(20);

      _movements = (response as List)
          .map((json) => StockMovement.fromJson(json))
          .toList();

      // Store movements offline for future use
      await OfflineStorageService.storeMovements(
          response.cast<Map<String, dynamic>>());

      _isShowingOfflineData = false;
      notifyListeners();
    } catch (e) {
      // If online fetch fails, try to load from offline storage
      _loadOfflineMovements();
      _setError('Failed to fetch movements: ${e.toString()}');
    }
  }

  void _loadOfflineMovements() {
    try {
      final offlineMovements = OfflineStorageService.getStoredMovements();
      _movements =
          offlineMovements.map((json) => StockMovement.fromJson(json)).toList();

      _isShowingOfflineData = true;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load offline movements: ${e.toString()}');
    }
  }

  Future<bool> moveStock({
    required String productId,
    required String fromLocationId,
    required String toLocationId,
    required int quantity,
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

      // Check if source has enough stock
      final sourceStock = _stocks.firstWhere(
        (stock) =>
            stock.productId == productId && stock.locationId == fromLocationId,
        orElse: () => Stock(
          id: '',
          productId: productId,
          locationId: fromLocationId,
          quantity: 0,
          updatedAt: DateTime.now(),
        ),
      );

      if (sourceStock.quantity < quantity) {
        _setError('Insufficient stock in source location');
        _setLoading(false);
        return false;
      }

      final movementData = {
        'product_id': productId,
        'from_location_id': fromLocationId,
        'to_location_id': toLocationId,
        'quantity': quantity,
        'movement_type': 'transfer',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      };

      // If offline, store as pending action
      if (!_connectivity.isOnline) {
        await SyncService.addPendingAction(
            'create_stock_movement', movementData);

        // Update local stock quantities
        _updateLocalStockQuantity(productId, fromLocationId, -quantity);
        _updateLocalStockQuantity(productId, toLocationId, quantity);

        // Add to local movements list
        _movements.insert(
            0,
            StockMovement.fromJson({
              ...movementData,
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'products': {
                'product_name': 'Unknown Product'
              }, // Will be updated when synced
              'from_location': {'location_name': 'Unknown Location'},
              'to_location': {'location_name': 'Unknown Location'},
            }));

        _setLoading(false);
        notifyListeners();
        return true;
      }

      // Online: perform normal operation
      await _supabase
          .from(SupabaseConfig.stockMovementsTable)
          .insert(movementData);

      // Update stock quantities
      await _updateStockQuantity(productId, fromLocationId, -quantity);
      await _updateStockQuantity(productId, toLocationId, quantity);

      // Send notification to all users about stock movement
      try {
        final productResponse = await _supabase
            .from(SupabaseConfig.productsTable)
            .select('product_name')
            .eq('id', productId)
            .single();

        final fromLocationResponse = await _supabase
            .from(SupabaseConfig.stockLocationsTable)
            .select('location_name')
            .eq('id', fromLocationId)
            .single();

        final toLocationResponse = await _supabase
            .from(SupabaseConfig.stockLocationsTable)
            .select('location_name')
            .eq('id', toLocationId)
            .single();

        await OneSignalService.sendNotificationToAll(
          title: '🚚 Stock Moved',
          message:
              '$quantity units of ${productResponse['product_name']} moved from ${fromLocationResponse['location_name']} to ${toLocationResponse['location_name']}',
          data: {
            'type': 'stock_movement',
            'product_id': productId,
            'from_location_id': fromLocationId,
            'to_location_id': toLocationId,
            'quantity': quantity,
          },
        );
      } catch (e) {
        // Don't fail the operation if notification fails
        AppLogger.error('Failed to send stock movement notification', error: e);
      }

      await fetchStocks();
      await fetchMovements();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to move stock: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  void _updateLocalStockQuantity(
      String productId, String locationId, int quantityChange) {
    final stockIndex = _stocks.indexWhere(
      (stock) => stock.productId == productId && stock.locationId == locationId,
    );

    if (stockIndex != -1) {
      _stocks[stockIndex] = Stock(
        id: _stocks[stockIndex].id,
        productId: productId,
        locationId: locationId,
        quantity: _stocks[stockIndex].quantity + quantityChange,
        updatedAt: DateTime.now(),
      );
    } else {
      // Create new stock entry locally
      _stocks.add(Stock(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: productId,
        locationId: locationId,
        quantity: quantityChange,
        updatedAt: DateTime.now(),
      ));
    }
  }

  Future<void> _updateStockQuantity(
      String productId, String locationId, int quantityChange) async {
    final existingStock = _stocks.firstWhere(
      (stock) => stock.productId == productId && stock.locationId == locationId,
      orElse: () => Stock(
        id: '',
        productId: productId,
        locationId: locationId,
        quantity: 0,
        updatedAt: DateTime.now(),
      ),
    );

    final newQuantity = existingStock.quantity + quantityChange;

    if (existingStock.id.isEmpty) {
      // Create new stock entry
      await _supabase.from(SupabaseConfig.stockLevelsTable).insert({
        'product_id': productId,
        'location_id': locationId,
        'quantity': newQuantity,
      });
    } else {
      // Update existing stock entry
      await _supabase
          .from(SupabaseConfig.stockLevelsTable)
          .update({'quantity': newQuantity}).eq('id', existingStock.id);
    }
  }

  Future<bool> addProduction({
    required String productId,
    required String locationId,
    required int quantity,
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

      // Record the production movement
      await _supabase.from(SupabaseConfig.stockMovementsTable).insert({
        'product_id': productId,
        'to_location_id': locationId, // Production adds to location
        'quantity': quantity,
        'movement_type': 'production',
        'notes': notes,
      });

      // Add stock quantity to the location
      await _updateStockQuantity(productId, locationId, quantity);

      // Send notification to all users about new production
      try {
        final productResponse = await _supabase
            .from(SupabaseConfig.productsTable)
            .select('product_name')
            .eq('id', productId)
            .single();

        final locationResponse = await _supabase
            .from(SupabaseConfig.stockLocationsTable)
            .select('location_name')
            .eq('id', locationId)
            .single();

        await OneSignalService.sendNotificationToAll(
          title: '📦 নতুন প্রোডাক্ট স্টকে যুক্ত করা হয়েছে',
          message:
              '$quantity units of ${productResponse['product_name']} added to ${locationResponse['location_name']}',
          data: {
            'type': 'production',
            'product_id': productId,
            'location_id': locationId,
            'quantity': quantity,
          },
        );
      } catch (e) {
        // Don't fail the operation if notification fails
        AppLogger.error('Failed to send production notification', error: e);
      }

      await fetchStocks();
      await fetchMovements();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add production: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
}
