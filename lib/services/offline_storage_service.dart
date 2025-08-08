import 'package:hive_flutter/hive_flutter.dart';

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

      // Open all boxes
      _productsHiveBox = await Hive.openBox(_productsBox);
      _stocksHiveBox = await Hive.openBox(_stocksBox);
      _salesHiveBox = await Hive.openBox(_salesBox);
      _movementsHiveBox = await Hive.openBox(_movementsBox);
      _notificationsHiveBox = await Hive.openBox(_notificationsBox);
      _pendingActionsHiveBox = await Hive.openBox(_pendingActionsBox);
      _userProfileHiveBox = await Hive.openBox(_userProfileBox);

      _isInitialized = true;
      print('✅ Offline storage initialized successfully');
    } catch (e) {
      print('❌ Error initializing offline storage: $e');
      throw e;
    }
  }

  static bool get isInitialized => _isInitialized;

  // Products offline storage
  static Future<void> storeProducts(List<Map<String, dynamic>> products) async {
    await _productsHiveBox.put('products', products);
  }

  static List<Map<String, dynamic>> getStoredProducts() {
    final products = _productsHiveBox
        .get('products', defaultValue: <Map<String, dynamic>>[]);
    return List<Map<String, dynamic>>.from(products);
  }

  // Stocks offline storage
  static Future<void> storeStocks(List<Map<String, dynamic>> stocks) async {
    await _stocksHiveBox.put('stocks', stocks);
  }

  static List<Map<String, dynamic>> getStoredStocks() {
    final stocks =
        _stocksHiveBox.get('stocks', defaultValue: <Map<String, dynamic>>[]);
    return List<Map<String, dynamic>>.from(stocks);
  }

  // Sales offline storage
  static Future<void> storeSales(List<Map<String, dynamic>> sales) async {
    await _salesHiveBox.put('sales', sales);
  }

  static List<Map<String, dynamic>> getStoredSales() {
    final sales =
        _salesHiveBox.get('sales', defaultValue: <Map<String, dynamic>>[]);
    return List<Map<String, dynamic>>.from(sales);
  }

  // Stock movements offline storage
  static Future<void> storeMovements(
      List<Map<String, dynamic>> movements) async {
    await _movementsHiveBox.put('movements', movements);
  }

  static List<Map<String, dynamic>> getStoredMovements() {
    final movements = _movementsHiveBox
        .get('movements', defaultValue: <Map<String, dynamic>>[]);
    return List<Map<String, dynamic>>.from(movements);
  }

  // Notifications offline storage
  static Future<void> storeNotifications(
      List<Map<String, dynamic>> notifications) async {
    await _notificationsHiveBox.put('notifications', notifications);
  }

  static List<Map<String, dynamic>> getStoredNotifications() {
    final notifications = _notificationsHiveBox
        .get('notifications', defaultValue: <Map<String, dynamic>>[]);
    return List<Map<String, dynamic>>.from(notifications);
  }

  // User profile offline storage
  static Future<void> storeUserProfile(Map<String, dynamic> profile) async {
    await _userProfileHiveBox.put('profile', profile);
  }

  static Map<String, dynamic>? getStoredUserProfile() {
    final profile = _userProfileHiveBox.get('profile');
    return profile != null ? Map<String, dynamic>.from(profile) : null;
  }

  // Pending actions for sync when online
  static Future<void> addPendingAction(Map<String, dynamic> action) async {
    final actions = getPendingActions();
    actions.add({
      ...action,
      'timestamp': DateTime.now().toIso8601String(),
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    await _pendingActionsHiveBox.put('actions', actions);
  }

  static List<Map<String, dynamic>> getPendingActions() {
    final actions = _pendingActionsHiveBox
        .get('actions', defaultValue: <Map<String, dynamic>>[]);
    return List<Map<String, dynamic>>.from(actions);
  }

  static Future<void> removePendingAction(String actionId) async {
    final actions = getPendingActions();
    actions.removeWhere((action) => action['id'] == actionId);
    await _pendingActionsHiveBox.put('actions', actions);
  }

  static Future<void> clearPendingActions() async {
    await _pendingActionsHiveBox.clear();
  }

  // Generic storage methods
  static Future<void> storeData(
      String boxName, String key, dynamic data) async {
    Box box;
    switch (boxName) {
      case _productsBox:
        box = _productsHiveBox;
        break;
      case _stocksBox:
        box = _stocksHiveBox;
        break;
      case _salesBox:
        box = _salesHiveBox;
        break;
      case _movementsBox:
        box = _movementsHiveBox;
        break;
      case _notificationsBox:
        box = _notificationsHiveBox;
        break;
      case _pendingActionsBox:
        box = _pendingActionsHiveBox;
        break;
      case _userProfileBox:
        box = _userProfileHiveBox;
        break;
      default:
        throw Exception('Unknown box name: $boxName');
    }
    await box.put(key, data);
  }

  static dynamic getData(String boxName, String key, {dynamic defaultValue}) {
    Box box;
    switch (boxName) {
      case _productsBox:
        box = _productsHiveBox;
        break;
      case _stocksBox:
        box = _stocksHiveBox;
        break;
      case _salesBox:
        box = _salesHiveBox;
        break;
      case _movementsBox:
        box = _movementsHiveBox;
        break;
      case _notificationsBox:
        box = _notificationsHiveBox;
        break;
      case _pendingActionsBox:
        box = _pendingActionsHiveBox;
        break;
      case _userProfileBox:
        box = _userProfileHiveBox;
        break;
      default:
        throw Exception('Unknown box name: $boxName');
    }
    return box.get(key, defaultValue: defaultValue);
  }

  // Clear all offline data
  static Future<void> clearAllData() async {
    await Future.wait([
      _productsHiveBox.clear(),
      _stocksHiveBox.clear(),
      _salesHiveBox.clear(),
      _movementsHiveBox.clear(),
      _notificationsHiveBox.clear(),
      _userProfileHiveBox.clear(),
      // Don't clear pending actions as they need to be synced
    ]);
  }

  // Get storage info
  static Map<String, int> getStorageInfo() {
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


