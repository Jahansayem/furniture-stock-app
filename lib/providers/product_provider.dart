import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/product.dart';
import '../services/offline_storage_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../utils/logger.dart';

class ProductProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivity = ConnectivityService();

  bool _isLoading = false;
  String? _errorMessage;
  List<Product> _products = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Product> get products => _products;

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

  Future<void> fetchProducts() async {
    _setLoading(true);
    _clearError();

    try {
      if (_connectivity.isOnline) {
        // Fetch from server when online
        final response = await _supabase
            .from(SupabaseConfig.productsTable)
            .select()
            .order('created_at', ascending: false);

        final productList = (response as List)
            .map((json) => json as Map<String, dynamic>)
            .toList();

        // Store in offline storage
        await OfflineStorageService.storeProducts(productList);

        _products = productList.map((json) => Product.fromJson(json)).toList();
      } else {
        // Load from offline storage when offline
        final offlineProducts = OfflineStorageService.getStoredProducts();
        _products =
            offlineProducts.map((json) => Product.fromJson(json)).toList();

        if (_products.isEmpty) {
          _setError(
              'No products available offline. Please connect to the internet to sync data.');
        }
      }
    } catch (e) {
      // Try loading from offline storage as fallback
      try {
        final offlineProducts = OfflineStorageService.getStoredProducts();
        _products =
            offlineProducts.map((json) => Product.fromJson(json)).toList();

        if (_products.isEmpty) {
          _setError('Failed to fetch products: ${e.toString()}');
        } else {
          _setError(
              'Using offline data. Failed to sync with server: ${e.toString()}');
        }
      } catch (offlineError) {
        _setError('Failed to fetch products: ${e.toString()}');
      }
    }

    _setLoading(false);
  }

  Future<bool> addProduct({
    required String productName,
    required String productType,
    String? description,
    String? imageUrl,
    int lowStockThreshold = 10,
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

      final productData = {
        'product_name': productName,
        'product_type': productType,
        'description': description,
        'image_url': imageUrl,
        'low_stock_threshold': lowStockThreshold,
        'created_by': user.id,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (_connectivity.isOnline) {
        // Add to server when online
        final response = await _supabase
            .from(SupabaseConfig.productsTable)
            .insert(productData)
            .select()
            .single();

        final newProduct = Product.fromJson(response);
        _products.insert(0, newProduct);

        // Update offline storage
        await OfflineStorageService.storeProducts(
            _products.map((p) => p.toJson()).toList());
      } else {
        // Store as pending action when offline
        await SyncService.addPendingAction('create_product', productData);

        // Create temporary product for local display
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final tempProduct = Product.fromJson({
          'id': tempId,
          ...productData,
        });

        _products.insert(0, tempProduct);

        // Update offline storage
        await OfflineStorageService.storeProducts(
            _products.map((p) => p.toJson()).toList());

        _setError('Product saved offline. Will sync when online.');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add product: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabase.from(SupabaseConfig.productsTable).update({
        'product_name': product.productName,
        'product_type': product.productType,
        'description': product.description,
        'image_url': product.imageUrl,
        'low_stock_threshold': product.lowStockThreshold,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', product.id);

      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product.copyWith(updatedAt: DateTime.now());
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update product: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      AppLogger.debug('Attempting to delete product: $productId');

      // First check if product exists
      final product = await _supabase
          .from(SupabaseConfig.productsTable)
          .select()
          .eq('id', productId)
          .single();

      AppLogger.debug('Product found: ${product['product_name']}');

      // Check for foreign key constraints
      final stockEntries = await _supabase
          .from('stocks')
          .select('id')
          .eq('product_id', productId);

      AppLogger.debug('Stock entries for this product: ${stockEntries.length}');

      if (stockEntries.isNotEmpty) {
        _setError(
            'Cannot delete product: It has associated stock entries. Please remove stock entries first.');
        _setLoading(false);
        return false;
      }

      // Delete the product
      await _supabase
          .from(SupabaseConfig.productsTable)
          .delete()
          .eq('id', productId);

      AppLogger.info('Product deleted successfully');

      // Refresh the products list from server to ensure consistency
      await fetchProducts();

      return true;
    } catch (e) {
      AppLogger.error('Error deleting product', error: e);
      _setError('Failed to delete product: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  void clearError() {
    _clearError();
  }
}
