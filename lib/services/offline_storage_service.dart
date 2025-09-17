import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';

class OfflineStorageService {
  static const String _productsBox = 'products_offline';
  static const String _stocksBox = 'stocks_offline';
  static const String _salesBox = 'sales_offline';
  static const String _movementsBox = 'movements_offline';
  static const String _notificationsBox = 'notifications_offline';
  static const String _pendingActionsBox = 'pending_actions';
  static const String _userProfileBox = 'user_profile_offline';

  static late Box _productsHiveBox;
  static late Box _stocksHiveBox;
  static late Box _salesHiveBox;
  static late Box _movementsHiveBox;
  static late Box _notificationsHiveBox;
  static late Box _pendingActionsHiveBox;
  static late Box _userProfileHiveBox;

  static bool _isInitialized = false;

  /// Initialize Hive and open all required boxes
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      // Chat features have been removed

      // Open all boxes
      _productsHiveBox = await Hive.openBox(_productsBox);
      _stocksHiveBox = await Hive.openBox(_stocksBox);
      _salesHiveBox = await Hive.openBox(_salesBox);
      _movementsHiveBox = await Hive.openBox(_movementsBox);
      _notificationsHiveBox = await Hive.openBox(_notificationsBox);
      _pendingActionsHiveBox = await Hive.openBox(_pendingActionsBox);
      _userProfileHiveBox = await Hive.openBox(_userProfileBox);

      _isInitialized = true;
      AppLogger.info('Offline storage initialized successfully');
    } catch (e) {
      AppLogger.error('Error initializing offline storage', error: e);
      rethrow;
    }
  }

  // Products offline storage
  static Future<void> storeProducts(List<Map<String, dynamic>> products) async {
    try {
      await _productsHiveBox.clear();
      for (int i = 0; i < products.length; i++) {
        await _productsHiveBox.put(products[i]['id'], products[i]);
      }
      AppLogger.info('Stored ${products.length} products offline');
    } catch (e) {
      AppLogger.error('Error storing products offline', error: e);
      throw e;
    }
  }

  static List<Map<String, dynamic>> getProducts() {
    try {
      return _productsHiveBox.values.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      AppLogger.error('Error getting products from offline storage', error: e);
      return [];
    }
  }

  static Future<void> storeProduct(Map<String, dynamic> product) async {
    try {
      await _productsHiveBox.put(product['id'], product);
      AppLogger.debug('Stored product ${product['id']} offline');
    } catch (e) {
      AppLogger.error('Error storing product offline', error: e);
      throw e;
    }
  }

  // Stocks offline storage
  static Future<void> storeStocks(List<Map<String, dynamic>> stocks) async {
    try {
      await _stocksHiveBox.clear();
      for (int i = 0; i < stocks.length; i++) {
        await _stocksHiveBox.put(stocks[i]['id'], stocks[i]);
      }
      AppLogger.info('Stored ${stocks.length} stocks offline');
    } catch (e) {
      AppLogger.error('Error storing stocks offline', error: e);
      throw e;
    }
  }

  static List<Map<String, dynamic>> getStocks() {
    try {
      return _stocksHiveBox.values.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      AppLogger.error('Error getting stocks from offline storage', error: e);
      return [];
    }
  }

  static Future<void> storeStock(Map<String, dynamic> stock) async {
    try {
      await _stocksHiveBox.put(stock['id'], stock);
      AppLogger.debug('Stored stock ${stock['id']} offline');
    } catch (e) {
      AppLogger.error('Error storing stock offline', error: e);
      throw e;
    }
  }

  // Sales offline storage
  static Future<void> storeSales(List<Map<String, dynamic>> sales) async {
    try {
      await _salesHiveBox.clear();
      for (int i = 0; i < sales.length; i++) {
        await _salesHiveBox.put(sales[i]['id'], sales[i]);
      }
      AppLogger.info('Stored ${sales.length} sales offline');
    } catch (e) {
      AppLogger.error('Error storing sales offline', error: e);
      throw e;
    }
  }

  static List<Map<String, dynamic>> getSales() {
    try {
      return _salesHiveBox.values.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      AppLogger.error('Error getting sales from offline storage', error: e);
      return [];
    }
  }

  static Future<void> storeSale(Map<String, dynamic> sale) async {
    try {
      await _salesHiveBox.put(sale['id'], sale);
      AppLogger.debug('Stored sale ${sale['id']} offline');
    } catch (e) {
      AppLogger.error('Error storing sale offline', error: e);
      throw e;
    }
  }

  // Stock movements offline storage
  static Future<void> storeMovements(List<Map<String, dynamic>> movements) async {
    try {
      await _movementsHiveBox.clear();
      for (int i = 0; i < movements.length; i++) {
        await _movementsHiveBox.put(movements[i]['id'], movements[i]);
      }
      AppLogger.info('Stored ${movements.length} movements offline');
    } catch (e) {
      AppLogger.error('Error storing movements offline', error: e);
      throw e;
    }
  }

  static List<Map<String, dynamic>> getMovements() {
    try {
      return _movementsHiveBox.values.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      AppLogger.error('Error getting movements from offline storage', error: e);
      return [];
    }
  }

  static Future<void> storeMovement(Map<String, dynamic> movement) async {
    try {
      await _movementsHiveBox.put(movement['id'], movement);
      AppLogger.debug('Stored movement ${movement['id']} offline');
    } catch (e) {
      AppLogger.error('Error storing movement offline', error: e);
      throw e;
    }
  }

  // Notifications offline storage
  static Future<void> storeNotifications(List<Map<String, dynamic>> notifications) async {
    try {
      await _notificationsHiveBox.clear();
      for (int i = 0; i < notifications.length; i++) {
        await _notificationsHiveBox.put(notifications[i]['id'], notifications[i]);
      }
      AppLogger.info('Stored ${notifications.length} notifications offline');
    } catch (e) {
      AppLogger.error('Error storing notifications offline', error: e);
      throw e;
    }
  }

  static List<Map<String, dynamic>> getNotifications() {
    try {
      return _notificationsHiveBox.values.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      AppLogger.error('Error getting notifications from offline storage', error: e);
      return [];
    }
  }

  static Future<void> storeNotification(Map<String, dynamic> notification) async {
    try {
      await _notificationsHiveBox.put(notification['id'], notification);
      AppLogger.debug('Stored notification ${notification['id']} offline');
    } catch (e) {
      AppLogger.error('Error storing notification offline', error: e);
      throw e;
    }
  }

  // Pending actions for sync when online
  static Future<void> addPendingAction(Map<String, dynamic> action) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await _pendingActionsHiveBox.put(timestamp, action);
      AppLogger.debug('Added pending action: ${action['type']}');
    } catch (e) {
      AppLogger.error('Error adding pending action', error: e);
      throw e;
    }
  }

  static List<Map<String, dynamic>> getPendingActions() {
    try {
      return _pendingActionsHiveBox.values.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      AppLogger.error('Error getting pending actions', error: e);
      return [];
    }
  }

  static Future<void> clearPendingActions() async {
    try {
      await _pendingActionsHiveBox.clear();
      AppLogger.info('Cleared all pending actions');
    } catch (e) {
      AppLogger.error('Error clearing pending actions', error: e);
      throw e;
    }
  }

  // User profile offline storage
  static Future<void> storeUserProfile(Map<String, dynamic> profile) async {
    try {
      await _userProfileHiveBox.put('current_user', profile);
      AppLogger.debug('Stored user profile offline');
    } catch (e) {
      AppLogger.error('Error storing user profile offline', error: e);
      throw e;
    }
  }

  static Map<String, dynamic>? getUserProfile() {
    try {
      return _userProfileHiveBox.get('current_user');
    } catch (e) {
      AppLogger.error('Error getting user profile from offline storage', error: e);
      return null;
    }
  }

  // Get storage statistics
  static Map<String, int> getStorageStats() {
    return {
      'products': _productsHiveBox.length,
      'stocks': _stocksHiveBox.length,
      'sales': _salesHiveBox.length,
      'movements': _movementsHiveBox.length,
      'notifications': _notificationsHiveBox.length,
      'pendingActions': _pendingActionsHiveBox.length,
      'userProfile': _userProfileHiveBox.length,
    };
  }

  // Chat features have been removed from the application

  // Legacy method names for compatibility
  static List<Map<String, dynamic>> getStoredProducts() {
    return getProducts();
  }

  static List<Map<String, dynamic>> getStoredMovements() {
    return getMovements();
  }

  static Future<void> removePendingAction(String timestamp) async {
    try {
      await _pendingActionsHiveBox.delete(timestamp);
      AppLogger.debug('Removed pending action: $timestamp');
    } catch (e) {
      AppLogger.error('Error removing pending action', error: e);
      throw e;
    }
  }

  static Map<String, dynamic> getStorageInfo() {
    return {
      'isInitialized': _isInitialized,
      'stats': getStorageStats(),
    };
  }

  // Close all boxes
  static Future<void> close() async {
    await Future.wait([
      _productsHiveBox.close(),
      _stocksHiveBox.close(),
      _salesHiveBox.close(),
      _movementsHiveBox.close(),
      _notificationsHiveBox.close(),
      _pendingActionsHiveBox.close(),
      _userProfileHiveBox.close(),
    ]);
    _isInitialized = false;
  }
}