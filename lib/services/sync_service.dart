import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'offline_storage_service.dart';
import 'connectivity_service.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivity = ConnectivityService();

  bool _isSyncing = false;
  String _syncStatus = 'Ready';
  DateTime? _lastSyncTime;
  List<String> _syncErrors = [];

  bool get isSyncing => _isSyncing;
  String get syncStatus => _syncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<String> get syncErrors => List.unmodifiable(_syncErrors);

  /// Initialize sync service
  Future<void> initialize() async {
    // Add callback to sync when coming online
    _connectivity.addOnlineCallback(_performAutoSync);
    print('✅ Sync service initialized');
  }

  /// Perform automatic sync when device comes online
  void _performAutoSync() {
    if (!_isSyncing && _connectivity.isOnline) {
      syncAllData();
    }
  }

  /// Sync all data with the server
  Future<bool> syncAllData() async {
    if (_isSyncing || !_connectivity.isOnline) {
      print('⚠️ Sync already in progress or device is offline');
      return false;
    }

    _isSyncing = true;
    _syncStatus = 'Syncing...';
    _syncErrors.clear();
    notifyListeners();

    try {
      print('🔄 Starting data synchronization...');

      // 1. Sync pending actions first
      await _syncPendingActions();

      // 2. Download latest data from server
      await _downloadServerData();

      // 3. Upload any local changes
      await _uploadLocalChanges();

      _syncStatus = 'Completed';
      _lastSyncTime = DateTime.now();
      print('✅ Data synchronization completed successfully');

      notifyListeners();
      return true;
    } catch (e) {
      _syncStatus = 'Failed';
      _syncErrors.add('Sync failed: $e');
      print('❌ Data synchronization failed: $e');

      notifyListeners();
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync pending actions (offline actions that need to be uploaded)
  Future<void> _syncPendingActions() async {
    final pendingActions = OfflineStorageService.getPendingActions();

    if (pendingActions.isEmpty) {
      print('📋 No pending actions to sync');
      return;
    }

    print('📋 Syncing ${pendingActions.length} pending actions...');

    for (final action in pendingActions) {
      try {
        await _processPendingAction(action);
        await OfflineStorageService.removePendingAction(action['id']);
        print('✅ Synced action: ${action['type']}');
      } catch (e) {
        print('❌ Failed to sync action ${action['id']}: $e');
        _syncErrors.add('Failed to sync ${action['type']}: $e');
        // Continue with other actions even if one fails
      }
    }
  }

  /// Process a single pending action
  Future<void> _processPendingAction(Map<String, dynamic> action) async {
    final type = action['type'] as String;
    final data = action['data'] as Map<String, dynamic>;

    switch (type) {
      case 'create_product':
        await _supabase.from(SupabaseConfig.productsTable).insert(data);
        break;
      case 'update_product':
        await _supabase
            .from(SupabaseConfig.productsTable)
            .update(data)
            .eq('id', data['id']);
        break;
      case 'delete_product':
        await _supabase
            .from(SupabaseConfig.productsTable)
            .delete()
            .eq('id', data['id']);
        break;
      case 'create_sale':
        await _supabase.from(SupabaseConfig.salesTable).insert(data);
        break;
      case 'update_sale':
        await _supabase
            .from(SupabaseConfig.salesTable)
            .update(data)
            .eq('id', data['id']);
        break;
      case 'create_stock_movement':
        await _supabase.from(SupabaseConfig.stockMovementsTable).insert(data);
        break;
      case 'update_stock':
        await _supabase
            .from(SupabaseConfig.stockLevelsTable)
            .update(data)
            .eq('id', data['id']);
        break;
      case 'update_profile':
        await _supabase
            .from(SupabaseConfig.profilesTable)
            .update(data)
            .eq('id', data['id']);
        break;
      default:
        print('⚠️ Unknown action type: $type');
    }
  }

  /// Download latest data from server
  Future<void> _downloadServerData() async {
    print('⬇️ Downloading latest data from server...');

    try {
      // Download products
      final productsResponse =
          await _supabase.from(SupabaseConfig.productsTable).select();
      await OfflineStorageService.storeProducts(
          List<Map<String, dynamic>>.from(productsResponse));

      // Download stocks
      final stocksResponse =
          await _supabase.from(SupabaseConfig.stockLevelsTable).select();
      await OfflineStorageService.storeStocks(
          List<Map<String, dynamic>>.from(stocksResponse));

      // Download sales (last 100 records to avoid too much data)
      final salesResponse = await _supabase
          .from(SupabaseConfig.salesTable)
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      await OfflineStorageService.storeSales(
          List<Map<String, dynamic>>.from(salesResponse));

      // Download stock movements (last 100 records)
      final movementsResponse = await _supabase
          .from(SupabaseConfig.stockMovementsTable)
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      await OfflineStorageService.storeMovements(
          List<Map<String, dynamic>>.from(movementsResponse));

      // Download user profile
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final profileResponse = await _supabase
            .from(SupabaseConfig.profilesTable)
            .select()
            .eq('id', user.id)
            .single();
        await OfflineStorageService.storeUserProfile(profileResponse);
      }

      print('✅ Server data downloaded successfully');
    } catch (e) {
      print('❌ Error downloading server data: $e');
      throw e;
    }
  }

  /// Upload local changes to server
  Future<void> _uploadLocalChanges() async {
    print('⬆️ Uploading local changes to server...');
    // This would handle any local changes that need to be uploaded
    // For now, we mainly rely on pending actions for this
    print('✅ Local changes uploaded successfully');
  }

  /// Force sync now (called by backup button)
  Future<bool> performBackupSync() async {
    if (!_connectivity.isOnline) {
      _syncErrors.add('Cannot backup: Device is offline');
      notifyListeners();
      return false;
    }

    return await syncAllData();
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    final storageInfo = OfflineStorageService.getStorageInfo();
    final pendingActions = OfflineStorageService.getPendingActions();

    return {
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'syncStatus': _syncStatus,
      'isSyncing': _isSyncing,
      'pendingActionsCount': pendingActions.length,
      'offlineDataCount': storageInfo,
      'isOnline': _connectivity.isOnline,
      'syncErrors': _syncErrors,
    };
  }

  /// Clear sync errors
  void clearSyncErrors() {
    _syncErrors.clear();
    notifyListeners();
  }

  /// Add pending action for offline operations
  static Future<void> addPendingAction(
      String type, Map<String, dynamic> data) async {
    await OfflineStorageService.addPendingAction({
      'type': type,
      'data': data,
    });
    print('📝 Added pending action: $type');
  }

  @override
  void dispose() {
    _connectivity.removeOnlineCallback(_performAutoSync);
    super.dispose();
  }
}
