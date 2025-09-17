import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/warehouse.dart';
import '../services/offline_storage_service.dart';
import '../services/sync_service.dart';
import '../utils/logger.dart';

class WarehouseProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Warehouse> _warehouses = [];
  Warehouse? _selectedWarehouse;
  List<StockTransfer> _transfers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Warehouse> get warehouses => _warehouses;
  Warehouse? get selectedWarehouse => _selectedWarehouse;
  List<StockTransfer> get transfers => _transfers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered lists
  List<Warehouse> get activeWarehouses => 
    _warehouses.where((w) => w.isActive).toList();

  List<Warehouse> get factoryWarehouses => 
    _warehouses.where((w) => w.type == WarehouseType.factory && w.isActive).toList();

  List<Warehouse> get showroomWarehouses => 
    _warehouses.where((w) => w.type == WarehouseType.showroom && w.isActive).toList();

  List<StockTransfer> get pendingTransfers =>
    _transfers.where((t) => t.status == TransferStatus.pending).toList();

  List<StockTransfer> get approvedTransfers =>
    _transfers.where((t) => t.status == TransferStatus.approved).toList();

  List<StockTransfer> get completedTransfers =>
    _transfers.where((t) => t.status == TransferStatus.completed).toList();

  // Initialize
  Future<void> initialize() async {
    await fetchWarehouses();
    await fetchTransfers();
  }

  // Fetch all warehouses
  Future<void> fetchWarehouses() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from(SupabaseConfig.warehousesTable)
          .select()
          .order('name');

      _warehouses = (response as List)
          .map((json) => Warehouse.fromJson(json))
          .toList();

      // Cache offline
      await _cacheWarehousesOffline();

      AppLogger.info('Fetched ${_warehouses.length} warehouses');
    } catch (e) {
      await _loadWarehousesFromCache();
      _setError('Failed to fetch warehouses: $e');
      AppLogger.error('Failed to fetch warehouses', error: e);
    } finally {
      _setLoading(false);
    }
  }

  // Select warehouse
  void selectWarehouse(Warehouse? warehouse) {
    if (_selectedWarehouse?.id == warehouse?.id) return;
    
    _selectedWarehouse = warehouse;
    notifyListeners();
    
    AppLogger.info('Selected warehouse: ${warehouse?.displayName ?? 'None'}');
  }

  // Create new warehouse
  Future<bool> createWarehouse(Warehouse warehouse) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from(SupabaseConfig.warehousesTable)
          .insert(warehouse.toJson())
          .select()
          .single();

      final newWarehouse = Warehouse.fromJson(response);
      _warehouses.add(newWarehouse);
      
      // Add to sync queue for offline support
      await SyncService().addPendingAction({
        'type': 'create_warehouse',
        'data': warehouse.toJson(),
      });

      AppLogger.info('Created warehouse: ${warehouse.displayName}');
      return true;
    } catch (e) {
      _setError('Failed to create warehouse: $e');
      AppLogger.error('Failed to create warehouse', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update warehouse
  Future<bool> updateWarehouse(Warehouse warehouse) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedWarehouse = warehouse.copyWith(
        updatedAt: DateTime.now(),
      );

      await _supabase
          .from(SupabaseConfig.warehousesTable)
          .update(updatedWarehouse.toJson())
          .eq('id', warehouse.id);

      final index = _warehouses.indexWhere((w) => w.id == warehouse.id);
      if (index != -1) {
        _warehouses[index] = updatedWarehouse;
      }

      // Update selected warehouse if it's the same
      if (_selectedWarehouse?.id == warehouse.id) {
        _selectedWarehouse = updatedWarehouse;
      }

      // Add to sync queue
      await SyncService().addPendingAction({
        'type': 'update_warehouse',
        'data': updatedWarehouse.toJson(),
      });

      AppLogger.info('Updated warehouse: ${warehouse.displayName}');
      return true;
    } catch (e) {
      _setError('Failed to update warehouse: $e');
      AppLogger.error('Failed to update warehouse', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Deactivate warehouse (soft delete)
  Future<bool> deactivateWarehouse(String warehouseId) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase
          .from(SupabaseConfig.warehousesTable)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', warehouseId);

      final index = _warehouses.indexWhere((w) => w.id == warehouseId);
      if (index != -1) {
        _warehouses[index] = _warehouses[index].copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
      }

      // Deselect if it was selected
      if (_selectedWarehouse?.id == warehouseId) {
        _selectedWarehouse = null;
      }

      AppLogger.info('Deactivated warehouse: $warehouseId');
      return true;
    } catch (e) {
      _setError('Failed to deactivate warehouse: $e');
      AppLogger.error('Failed to deactivate warehouse', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Stock Transfer Operations
  Future<void> fetchTransfers() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from(SupabaseConfig.stockTransfersTable)
          .select()
          .order('created_at', ascending: false);

      _transfers = (response as List)
          .map((json) => StockTransfer.fromJson(json))
          .toList();

      AppLogger.info('Fetched ${_transfers.length} stock transfers');
    } catch (e) {
      _setError('Failed to fetch transfers: $e');
      AppLogger.error('Failed to fetch transfers', error: e);
    } finally {
      _setLoading(false);
    }
  }

  // Create stock transfer
  Future<bool> createStockTransfer(StockTransfer transfer) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from(SupabaseConfig.stockTransfersTable)
          .insert(transfer.toJson())
          .select()
          .single();

      final newTransfer = StockTransfer.fromJson(response);
      _transfers.insert(0, newTransfer);

      // Add to sync queue
      await SyncService().addPendingAction({
        'type': 'create_stock_transfer',
        'data': transfer.toJson(),
      });

      AppLogger.info('Created stock transfer: ${transfer.id}');
      return true;
    } catch (e) {
      _setError('Failed to create transfer: $e');
      AppLogger.error('Failed to create transfer', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Approve stock transfer
  Future<bool> approveStockTransfer(String transferId, String approvedBy) async {
    try {
      _setLoading(true);
      _clearError();

      final updateData = {
        'status': TransferStatus.approved.value,
        'approved_by': approvedBy,
        'approved_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from(SupabaseConfig.stockTransfersTable)
          .update(updateData)
          .eq('id', transferId);

      final index = _transfers.indexWhere((t) => t.id == transferId);
      if (index != -1) {
        final original = _transfers[index];
        _transfers[index] = StockTransfer(
          id: original.id,
          productId: original.productId,
          productName: original.productName,
          fromWarehouseId: original.fromWarehouseId,
          fromWarehouseName: original.fromWarehouseName,
          toWarehouseId: original.toWarehouseId,
          toWarehouseName: original.toWarehouseName,
          quantity: original.quantity,
          status: TransferStatus.approved,
          initiatedBy: original.initiatedBy,
          approvedBy: approvedBy,
          completedBy: original.completedBy,
          createdAt: original.createdAt,
          approvedAt: DateTime.now(),
          completedAt: original.completedAt,
          notes: original.notes,
          rejectionReason: original.rejectionReason,
        );
      }

      AppLogger.info('Approved stock transfer: $transferId');
      return true;
    } catch (e) {
      _setError('Failed to approve transfer: $e');
      AppLogger.error('Failed to approve transfer', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Complete stock transfer
  Future<bool> completeStockTransfer(String transferId, String completedBy) async {
    try {
      _setLoading(true);
      _clearError();

      final updateData = {
        'status': TransferStatus.completed.value,
        'completed_by': completedBy,
        'completed_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from(SupabaseConfig.stockTransfersTable)
          .update(updateData)
          .eq('id', transferId);

      final index = _transfers.indexWhere((t) => t.id == transferId);
      if (index != -1) {
        final original = _transfers[index];
        _transfers[index] = StockTransfer(
          id: original.id,
          productId: original.productId,
          productName: original.productName,
          fromWarehouseId: original.fromWarehouseId,
          fromWarehouseName: original.fromWarehouseName,
          toWarehouseId: original.toWarehouseId,
          toWarehouseName: original.toWarehouseName,
          quantity: original.quantity,
          status: TransferStatus.completed,
          initiatedBy: original.initiatedBy,
          approvedBy: original.approvedBy,
          completedBy: completedBy,
          createdAt: original.createdAt,
          approvedAt: original.approvedAt,
          completedAt: DateTime.now(),
          notes: original.notes,
          rejectionReason: original.rejectionReason,
        );
      }

      AppLogger.info('Completed stock transfer: $transferId');
      return true;
    } catch (e) {
      _setError('Failed to complete transfer: $e');
      AppLogger.error('Failed to complete transfer', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel/Reject stock transfer
  Future<bool> cancelStockTransfer(String transferId, String reason) async {
    try {
      _setLoading(true);
      _clearError();

      final updateData = {
        'status': TransferStatus.cancelled.value,
        'rejection_reason': reason,
      };

      await _supabase
          .from(SupabaseConfig.stockTransfersTable)
          .update(updateData)
          .eq('id', transferId);

      final index = _transfers.indexWhere((t) => t.id == transferId);
      if (index != -1) {
        final original = _transfers[index];
        _transfers[index] = StockTransfer(
          id: original.id,
          productId: original.productId,
          productName: original.productName,
          fromWarehouseId: original.fromWarehouseId,
          fromWarehouseName: original.fromWarehouseName,
          toWarehouseId: original.toWarehouseId,
          toWarehouseName: original.toWarehouseName,
          quantity: original.quantity,
          status: TransferStatus.cancelled,
          initiatedBy: original.initiatedBy,
          approvedBy: original.approvedBy,
          completedBy: original.completedBy,
          createdAt: original.createdAt,
          approvedAt: original.approvedAt,
          completedAt: original.completedAt,
          notes: original.notes,
          rejectionReason: reason,
        );
      }

      AppLogger.info('Cancelled stock transfer: $transferId');
      return true;
    } catch (e) {
      _setError('Failed to cancel transfer: $e');
      AppLogger.error('Failed to cancel transfer', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get warehouse by ID
  Warehouse? getWarehouseById(String id) {
    try {
      return _warehouses.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get warehouses by type
  List<Warehouse> getWarehousesByType(WarehouseType type) {
    return _warehouses
        .where((w) => w.type == type && w.isActive)
        .toList();
  }

  // Search warehouses
  List<Warehouse> searchWarehouses(String query) {
    if (query.isEmpty) return activeWarehouses;
    
    final lowercaseQuery = query.toLowerCase();
    return _warehouses.where((w) =>
      w.isActive &&
      (w.name.toLowerCase().contains(lowercaseQuery) ||
       w.code.toLowerCase().contains(lowercaseQuery) ||
       w.address.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  // Offline support methods
  Future<void> _cacheWarehousesOffline() async {
    try {
      final storage = OfflineStorageService();
      await storage.storeWarehouses(_warehouses);
    } catch (e) {
      AppLogger.error('Failed to cache warehouses offline', error: e);
    }
  }

  Future<void> _loadWarehousesFromCache() async {
    try {
      final storage = OfflineStorageService();
      final cachedWarehouses = await storage.getWarehouses();
      if (cachedWarehouses.isNotEmpty) {
        _warehouses = cachedWarehouses;
        AppLogger.info('Loaded ${_warehouses.length} warehouses from cache');
      }
    } catch (e) {
      AppLogger.error('Failed to load warehouses from cache', error: e);
    }
  }

  // Utility methods
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

  void clearError() {
    _clearError();
  }
}