import 'package:flutter/material.dart';

/// Enhanced user role model with hierarchical permissions
class UserRole {
  final String id;
  final String roleName;
  final int roleLevel;
  final String displayName;
  final String? description;
  final Map<String, dynamic> permissions;
  final List<String> canManageRoles;
  final Map<String, dynamic> financialAccess;
  final List<String> locationRestrictions;
  final List<String> featureRestrictions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserRole({
    required this.id,
    required this.roleName,
    required this.roleLevel,
    required this.displayName,
    this.description,
    required this.permissions,
    required this.canManageRoles,
    required this.financialAccess,
    required this.locationRestrictions,
    required this.featureRestrictions,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user has specific permission
  bool hasPermission(String module, String action) {
    if (!permissions.containsKey(module)) return false;
    
    final modulePermissions = permissions[module] as Map<String, dynamic>?;
    if (modulePermissions == null) return false;
    
    return modulePermissions[action] == true;
  }

  /// Check if user can manage another role
  bool canManageRole(String targetRole) {
    return canManageRoles.contains(targetRole);
  }

  /// Check if user has financial access to specific data
  bool hasFinancialAccess(String dataType) {
    return financialAccess[dataType] == true;
  }

  /// Check if user can access specific location
  bool canAccessLocation(String locationId) {
    // Empty restrictions means access to all locations
    return locationRestrictions.isEmpty || locationRestrictions.contains(locationId);
  }

  /// Check if user can use specific feature
  bool canUseFeature(String featureName) {
    return !featureRestrictions.contains(featureName);
  }

  /// Get role color for UI
  Color getRoleColor() {
    switch (roleName) {
      case 'owner':
        return const Color(0xFF1565C0); // Deep Blue
      case 'admin':
        return const Color(0xFF2196F3); // Blue
      case 'manager':
        return const Color(0xFF00A859); // Green
      case 'employee':
        return const Color(0xFF9C27B0); // Purple
      case 'production_employee':
        return const Color(0xFFFF8C00); // Orange
      default:
        return const Color(0xFF666666); // Gray
    }
  }

  /// Get role icon for UI
  String getRoleIcon() {
    switch (roleName) {
      case 'owner':
        return '👑';
      case 'admin':
        return '🔧';
      case 'manager':
        return '📊';
      case 'employee':
        return '👤';
      case 'production_employee':
        return '🏭';
      default:
        return '👤';
    }
  }

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] as String,
      roleName: json['role_name'] as String,
      roleLevel: json['role_level'] as int,
      displayName: json['display_name'] as String,
      description: json['description'] as String?,
      permissions: json['permissions'] as Map<String, dynamic>? ?? {},
      canManageRoles: List<String>.from(json['can_manage_roles'] ?? []),
      financialAccess: json['financial_access'] as Map<String, dynamic>? ?? {},
      locationRestrictions: List<String>.from(json['location_restrictions'] ?? []),
      featureRestrictions: List<String>.from(json['feature_restrictions'] ?? []),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_name': roleName,
      'role_level': roleLevel,
      'display_name': displayName,
      'description': description,
      'permissions': permissions,
      'can_manage_roles': canManageRoles,
      'financial_access': financialAccess,
      'location_restrictions': locationRestrictions,
      'feature_restrictions': featureRestrictions,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserRole copyWith({
    String? id,
    String? roleName,
    int? roleLevel,
    String? displayName,
    String? description,
    Map<String, dynamic>? permissions,
    List<String>? canManageRoles,
    Map<String, dynamic>? financialAccess,
    List<String>? locationRestrictions,
    List<String>? featureRestrictions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserRole(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      roleLevel: roleLevel ?? this.roleLevel,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      canManageRoles: canManageRoles ?? this.canManageRoles,
      financialAccess: financialAccess ?? this.financialAccess,
      locationRestrictions: locationRestrictions ?? this.locationRestrictions,
      featureRestrictions: featureRestrictions ?? this.featureRestrictions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRole && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserRole(id: $id, roleName: $roleName, displayName: $displayName)';
  }
}

/// Permission constants for easy reference
class Permissions {
  // Product permissions
  static const String productsCreate = 'products.create';
  static const String productsRead = 'products.read';
  static const String productsUpdate = 'products.update';
  static const String productsDelete = 'products.delete';
  static const String productsImport = 'products.import';
  static const String productsExport = 'products.export';

  // Order permissions
  static const String ordersCreate = 'orders.create';
  static const String ordersRead = 'orders.read';
  static const String ordersUpdate = 'orders.update';
  static const String ordersDelete = 'orders.delete';
  static const String ordersCancel = 'orders.cancel';
  static const String ordersRefund = 'orders.refund';

  // Customer permissions
  static const String customersCreate = 'customers.create';
  static const String customersRead = 'customers.read';
  static const String customersUpdate = 'customers.update';
  static const String customersDelete = 'customers.delete';
  static const String customersExport = 'customers.export';

  // Financial permissions
  static const String financialViewAll = 'financial.view_all';
  static const String financialProfitMargins = 'financial.profit_margins';
  static const String financialCostData = 'financial.cost_data';
  static const String financialSalaryData = 'financial.salary_data';
  static const String financialViewSummary = 'financial.view_summary';
  static const String financialBasicReports = 'financial.basic_reports';

  // Reports permissions
  static const String reportsAll = 'reports.all_reports';
  static const String reportsFinancial = 'reports.financial';
  static const String reportsProfitLoss = 'reports.profit_loss';
  static const String reportsUserActivity = 'reports.user_activity';
  static const String reportsSales = 'reports.sales';
  static const String reportsInventory = 'reports.inventory';
  static const String reportsCustomer = 'reports.customer';

  // Settings permissions
  static const String settingsSystem = 'settings.system';
  static const String settingsUsers = 'settings.users';
  static const String settingsRoles = 'settings.roles';
  static const String settingsIntegrations = 'settings.integrations';
  static const String settingsBasic = 'settings.basic_settings';

  // Production permissions
  static const String productionManage = 'production.manage';
  static const String productionMaterials = 'production.materials';
  static const String productionCostManagement = 'production.cost_management';
  static const String productionView = 'production.view';
  static const String productionBasicManagement = 'production.basic_management';
  static const String productionAssignWork = 'production.assign_work';
  static const String productionTrackProgress = 'production.track_progress';
  static const String productionManageAssigned = 'production.manage_assigned';
  static const String productionMaterialRequests = 'production.material_requests';
  static const String productionQualityUpdates = 'production.quality_updates';

  // Stock permissions
  static const String stockRead = 'stock.read';
  static const String stockUpdate = 'stock.update';
  static const String stockUpdateStock = 'stock.update_stock';
  static const String stockTransfer = 'stock.transfer';
  static const String stockAdjust = 'stock.adjust';

  /// Check if a permission string is valid
  static bool isValidPermission(String permission) {
    return permission.contains('.') && permission.split('.').length == 2;
  }

  /// Get module from permission string
  static String getModule(String permission) {
    return permission.split('.').first;
  }

  /// Get action from permission string
  static String getAction(String permission) {
    return permission.split('.').last;
  }
}

/// Financial access levels
class FinancialAccess {
  static const String profitMargins = 'profit_margins';
  static const String costData = 'cost_data';
  static const String salaryData = 'salary_data';
  static const String basicReports = 'basic_reports';
  static const String locationReports = 'location_reports';
  static const String viewAll = 'view_all';
  static const String viewSummary = 'view_summary';
  static const String viewAssignedLocation = 'view_assigned_location';
  static const String viewOwnSales = 'view_own_sales';
}

/// Feature restrictions
class FeatureRestrictions {
  static const String adminPanel = 'admin_panel';
  static const String userManagement = 'user_management';
  static const String systemSettings = 'system_settings';
  static const String financialReports = 'financial_reports';
  static const String productionManagement = 'production_management';
  static const String supplierManagement = 'supplier_management';
}