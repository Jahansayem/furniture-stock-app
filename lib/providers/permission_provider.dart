import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_role.dart';
import '../utils/logger.dart';

/// Manages role-based permissions and access control
class PermissionProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  UserRole? _currentUserRole;
  List<UserRole> _availableRoles = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Getters
  UserRole? get currentUserRole => _currentUserRole;
  List<UserRole> get availableRoles => _availableRoles;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  /// Initialize permission provider with user role
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;
    
    _setLoading(true);
    try {
      await _loadUserRole(userId);
      await _loadAvailableRoles();
      _clearError();
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize permissions: ${e.toString()}');
      AppLogger.error('Permission initialization failed', error: e);
    } finally {
      _setLoading(false);
    }
  }

  /// Load current user's role and permissions
  Future<void> _loadUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('''
            *, 
            user_roles(*)
          ''')
          .eq('id', userId)
          .single();

      if (response['user_roles'] != null) {
        _currentUserRole = UserRole.fromJson(response['user_roles'] as Map<String, dynamic>);
        AppLogger.info('Loaded user role: ${_currentUserRole?.roleName}');
      } else {
        throw Exception('User role not found');
      }
    } catch (e) {
      AppLogger.error('Failed to load user role', error: e);
      rethrow;
    }
  }

  /// Load all available roles (for admin use)
  Future<void> _loadAvailableRoles() async {
    try {
      final response = await _supabase
          .from('user_roles')
          .select('*')
          .eq('is_active', true)
          .order('role_level');

      _availableRoles = (response as List)
          .map((json) => UserRole.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.info('Loaded ${_availableRoles.length} available roles');
    } catch (e) {
      AppLogger.error('Failed to load available roles', error: e);
      // Don't rethrow - this is not critical for basic functionality
    }
  }

  /// Check if current user has specific permission
  bool hasPermission(String permission) {
    if (_currentUserRole == null) return false;

    final parts = permission.split('.');
    if (parts.length != 2) return false;

    return _currentUserRole!.hasPermission(parts[0], parts[1]);
  }

  /// Check multiple permissions (AND logic)
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every((permission) => hasPermission(permission));
  }

  /// Check multiple permissions (OR logic)
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((permission) => hasPermission(permission));
  }

  /// Check if user can manage another user with specific role
  bool canManageRole(String targetRole) {
    if (_currentUserRole == null) return false;
    return _currentUserRole!.canManageRole(targetRole);
  }

  /// Check if user has financial access to specific data
  bool hasFinancialAccess(String dataType) {
    if (_currentUserRole == null) return false;
    return _currentUserRole!.hasFinancialAccess(dataType);
  }

  /// Check if user can access specific location
  bool canAccessLocation(String locationId) {
    if (_currentUserRole == null) return false;
    return _currentUserRole!.canAccessLocation(locationId);
  }

  /// Check if user can use specific feature
  bool canUseFeature(String featureName) {
    if (_currentUserRole == null) return true; // Default allow
    return _currentUserRole!.canUseFeature(featureName);
  }

  /// Get accessible locations for current user
  List<String> getAccessibleLocations() {
    if (_currentUserRole == null) return [];
    
    // If no restrictions, user can access all locations
    if (_currentUserRole!.locationRestrictions.isEmpty) {
      return []; // Empty list means all locations accessible
    }
    
    return _currentUserRole!.locationRestrictions;
  }

  /// Get role-specific navigation items
  List<NavigationItem> getRoleBasedNavigation() {
    if (_currentUserRole == null) return [];

    final items = <NavigationItem>[];

    // Always show dashboard
    items.add(const NavigationItem(
      route: '/home',
      label: 'Dashboard',
      icon: 'dashboard',
    ));

    // Orders - all roles except production_employee
    if (_currentUserRole!.roleName != 'production_employee') {
      items.add(const NavigationItem(
        route: '/orders',
        label: 'Orders',
        icon: 'list_alt',
      ));
    }

    // Stock - all roles
    items.add(const NavigationItem(
      route: '/stock',
      label: 'Stock',
      icon: 'store',
    ));

    // Products - if user can read products
    if (hasPermission(Permissions.productsRead)) {
      items.add(const NavigationItem(
        route: '/products',
        label: 'Products',
        icon: 'inventory_2',
      ));
    }

    // Production - only for production employees and managers
    if (_currentUserRole!.roleName == 'production_employee' || 
        hasPermission(Permissions.productionView)) {
      items.add(const NavigationItem(
        route: '/production',
        label: 'Production',
        icon: 'factory',
      ));
    }

    // Financial - only if has financial access
    if (hasAnyPermission([
      Permissions.financialViewAll,
      Permissions.financialViewSummary,
      Permissions.financialBasicReports,
    ])) {
      items.add(const NavigationItem(
        route: '/financial',
        label: 'Financial',
        icon: 'account_balance',
      ));
    }

    // Reports - if has report access
    if (hasAnyPermission([
      Permissions.reportsAll,
      Permissions.reportsSales,
      Permissions.reportsInventory,
    ])) {
      items.add(const NavigationItem(
        route: '/reports',
        label: 'Reports',
        icon: 'analytics',
      ));
    }

    // Settings - only for admin roles
    if (hasAnyPermission([
      Permissions.settingsSystem,
      Permissions.settingsUsers,
      Permissions.settingsBasic,
    ])) {
      items.add(const NavigationItem(
        route: '/settings',
        label: 'Settings',
        icon: 'settings',
      ));
    }

    return items;
  }

  /// Get roles that current user can assign to others
  List<UserRole> getManageableRoles() {
    if (_currentUserRole == null) return [];
    
    return _availableRoles.where((role) => 
        _currentUserRole!.canManageRole(role.roleName)
    ).toList();
  }

  /// Update user role (admin only)
  Future<bool> updateUserRole(String userId, String newRoleId) async {
    if (!hasPermission(Permissions.settingsUsers)) {
      _setError('Insufficient permissions to update user role');
      return false;
    }

    _setLoading(true);
    try {
      await _supabase
          .from('user_profiles')
          .update({'role_id': newRoleId})
          .eq('id', userId);

      AppLogger.info('Updated user role: $userId -> $newRoleId');
      return true;
    } catch (e) {
      _setError('Failed to update user role: ${e.toString()}');
      AppLogger.error('Failed to update user role', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create new role (owner only)
  Future<bool> createRole(UserRole role) async {
    if (!hasPermission(Permissions.settingsRoles)) {
      _setError('Insufficient permissions to create role');
      return false;
    }

    _setLoading(true);
    try {
      await _supabase
          .from('user_roles')
          .insert(role.toJson());

      await _loadAvailableRoles(); // Refresh roles
      AppLogger.info('Created new role: ${role.roleName}');
      return true;
    } catch (e) {
      _setError('Failed to create role: ${e.toString()}');
      AppLogger.error('Failed to create role', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing role (owner only)
  Future<bool> updateRole(UserRole role) async {
    if (!hasPermission(Permissions.settingsRoles)) {
      _setError('Insufficient permissions to update role');
      return false;
    }

    _setLoading(true);
    try {
      await _supabase
          .from('user_roles')
          .update(role.toJson())
          .eq('id', role.id);

      await _loadAvailableRoles(); // Refresh roles
      AppLogger.info('Updated role: ${role.roleName}');
      return true;
    } catch (e) {
      _setError('Failed to update role: ${e.toString()}');
      AppLogger.error('Failed to update role', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get role-based dashboard widgets
  List<String> getDashboardWidgets() {
    if (_currentUserRole == null) return [];

    final widgets = <String>['overview']; // Always show overview

    switch (_currentUserRole!.roleName) {
      case 'owner':
        widgets.addAll([
          'financial_summary',
          'profit_margins',
          'user_activity',
          'system_health',
          'advanced_analytics',
        ]);
        break;
      
      case 'admin':
        widgets.addAll([
          'sales_summary',
          'inventory_status',
          'order_tracking',
          'user_activity',
        ]);
        break;
        
      case 'manager':
        widgets.addAll([
          'location_sales',
          'team_performance',
          'inventory_alerts',
          'order_summary',
        ]);
        break;
        
      case 'employee':
        widgets.addAll([
          'my_sales',
          'quick_actions',
          'recent_orders',
        ]);
        break;
        
      case 'production_employee':
        widgets.addAll([
          'production_queue',
          'material_requests',
          'quality_metrics',
        ]);
        break;
    }

    return widgets;
  }

  /// Check if current role can view financial data
  bool canViewFinancialData([String? specificType]) {
    if (_currentUserRole == null) return false;
    
    if (specificType != null) {
      return _currentUserRole!.hasFinancialAccess(specificType);
    }
    
    return _currentUserRole!.hasFinancialAccess(FinancialAccess.viewAll) ||
           _currentUserRole!.hasFinancialAccess(FinancialAccess.viewSummary);
  }

  /// Check if current role can view profit margins
  bool canViewProfitMargins() {
    if (_currentUserRole == null) return false;
    return _currentUserRole!.hasFinancialAccess(FinancialAccess.profitMargins);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _currentUserRole = null;
    _availableRoles = [];
    _isLoading = false;
    _isInitialized = false;
    _error = null;
    notifyListeners();
  }
}

/// Navigation item for role-based navigation
class NavigationItem {
  final String route;
  final String label;
  final String icon;
  final List<String>? requiredPermissions;

  const NavigationItem({
    required this.route,
    required this.label,
    required this.icon,
    this.requiredPermissions,
  });
}

// Widget that shows content based on permissions
// Moved to separate widgets file to avoid Flutter import issues in providers