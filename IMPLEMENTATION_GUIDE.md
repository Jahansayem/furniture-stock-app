# FurniShop Manager - Frontend Implementation Guide

## Quick Start Implementation

### 1. Update Main App to Support Role-Based Navigation

Update `main.dart` to include the new providers:

```dart
// Add these to the MultiProvider in main.dart
ChangeNotifierProvider(create: (_) => RoleProvider()),
ChangeNotifierProvider(create: (_) => WarehouseProvider()),
```

### 2. Enhance AuthProvider Integration

Update `AuthProvider` to initialize `RoleProvider`:

```dart
// In AuthProvider._loadUserProfile()
if (_userProfile != null) {
  // Initialize role provider
  final roleProvider = Provider.of<RoleProvider>(context, listen: false);
  roleProvider.initialize(_userProfile!);
}
```

### 3. Update Supabase Config

Add new table references to `SupabaseConfig`:

```dart
class SupabaseConfig {
  // Existing tables...
  static const String warehousesTable = 'warehouses';
  static const String stockTransfersTable = 'stock_transfers';
  static const String employeesTable = 'employees';
  static const String attendanceTable = 'attendance_log';
  static const String productionOrdersTable = 'production_orders';
  static const String materialsTable = 'materials';
  static const String transactionsTable = 'financial_transactions';
}
```

### 4. Enhanced Navigation System

Replace the existing `MainLayout` in `main.dart` with role-aware navigation:

```dart
class MainLayout extends StatefulWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<RoleProvider>(
      builder: (context, roleProvider, child) {
        final navigationItems = roleProvider.getNavigationItems();
        
        return Scaffold(
          body: widget.child,
          bottomNavigationBar: AdaptiveBottomNavBar(
            items: navigationItems,
            currentRoute: GoRouterState.of(context).matchedLocation,
          ),
        );
      },
    );
  }
}
```

## Database Schema Updates

### Required Supabase Tables

```sql
-- Warehouses table
CREATE TABLE warehouses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR NOT NULL,
  code VARCHAR UNIQUE NOT NULL,
  address TEXT NOT NULL,
  latitude DECIMAL,
  longitude DECIMAL,
  type VARCHAR NOT NULL CHECK (type IN ('factory', 'showroom', 'storage', 'distribution', 'retail')),
  manager_id UUID REFERENCES auth.users(id),
  manager_name VARCHAR,
  is_active BOOLEAN DEFAULT true,
  description TEXT,
  capacity DECIMAL,
  contact_phone VARCHAR,
  contact_email VARCHAR,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Stock transfers table
CREATE TABLE stock_transfers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id),
  product_name VARCHAR NOT NULL,
  from_warehouse_id UUID REFERENCES warehouses(id),
  from_warehouse_name VARCHAR NOT NULL,
  to_warehouse_id UUID REFERENCES warehouses(id),
  to_warehouse_name VARCHAR NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  status VARCHAR NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'in_progress', 'completed', 'cancelled', 'rejected')),
  initiated_by UUID REFERENCES auth.users(id) NOT NULL,
  approved_by UUID REFERENCES auth.users(id),
  completed_by UUID REFERENCES auth.users(id),
  notes TEXT,
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  approved_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Update user_profiles table for enhanced roles
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS warehouse_id UUID REFERENCES warehouses(id),
ADD COLUMN IF NOT EXISTS employee_id VARCHAR,
ADD COLUMN IF NOT EXISTS department VARCHAR,
ADD COLUMN IF NOT EXISTS hire_date DATE,
ADD COLUMN IF NOT EXISTS salary DECIMAL,
ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{}';

-- Create indexes for performance
CREATE INDEX idx_warehouses_type ON warehouses(type);
CREATE INDEX idx_warehouses_active ON warehouses(is_active);
CREATE INDEX idx_stock_transfers_status ON stock_transfers(status);
CREATE INDEX idx_user_profiles_role ON user_profiles(role);
```

## Key Implementation Examples

### 1. Role-Based Route Protection

```dart
// In your router configuration
redirect: (context, state) {
  final roleProvider = Provider.of<RoleProvider>(context, listen: false);
  
  if (!roleProvider.canAccessRoute(state.matchedLocation)) {
    // Redirect to appropriate dashboard
    if (roleProvider.isOwner) return '/owner-dashboard';
    if (roleProvider.isManager) return '/manager-dashboard';
    if (roleProvider.isStaff) return '/staff-dashboard';
    return '/employee-dashboard';
  }
  
  return null; // Allow access
},
```

### 2. Conditional UI Rendering

```dart
// Example in any screen
Consumer<RoleProvider>(
  builder: (context, roleProvider, child) {
    return Column(
      children: [
        // Always visible
        BasicDataWidget(),
        
        // Owner only
        if (roleProvider.hasPermission(Permission.viewFinance))
          FinancialSummaryWidget(),
        
        // Manager and above
        if (roleProvider.hasPermission(Permission.viewEmployees))
          EmployeeManagementWidget(),
        
        // Staff and above
        if (roleProvider.hasPermission(Permission.viewStock))
          StockManagementWidget(),
      ],
    );
  },
)
```

### 3. Adaptive UI Components

```dart
// Example usage of adaptive components
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AdaptiveAppBar(
      title: 'Stock Management',
      subtitle: 'Warehouse: ${selectedWarehouse?.name}',
    ),
    body: ModernLoadingOverlay(
      isLoading: isLoading,
      message: 'Loading stock data...',
      child: Column(
        children: [
          ModernSearchBar(
            hintText: 'Search products...',
            onChanged: _handleSearch,
            showFilterButton: true,
            onFilterPressed: _showFilters,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ModernCard(
                  onTap: () => _showProductDetails(products[index]),
                  child: ProductListItem(products[index]),
                );
              },
            ),
          ),
        ],
      ),
    ),
    floatingActionButton: RoleBasedFAB(),
  );
}
```

## Step-by-Step Implementation Phases

### Phase 1: Foundation (Week 1)

1. **Install New Dependencies**
   ```yaml
   # Add to pubspec.yaml
   pdf: ^3.10.4              # For PDF generation
   printing: ^5.11.1         # For PDF preview/print
   image: ^4.1.3             # Image processing
   flutter_image_compress: ^2.0.4  # Image compression
   ```

2. **Create Core Models**
   - ✅ `UserRole` enum and `Permission` system
   - ✅ `Warehouse` model with transfer support
   - Create `Employee`, `ProductionOrder`, `Material`, `Transaction` models

3. **Setup Enhanced Providers**
   - ✅ `RoleProvider` for permission management
   - ✅ `WarehouseProvider` for multi-location support
   - Create `EmployeeProvider`, `ProductionProvider`, `FinanceProvider`

### Phase 2: UI Foundation (Week 2)

1. **Implement Base Components**
   - ✅ `AdaptiveAppBar` for role-based headers
   - ✅ `ModernCard`, `MetricCard`, `AnimatedStatusChip`
   - ✅ `ModernSearchBar`, `ModernBottomSheet`

2. **Role-Based Dashboard**
   - ✅ `OwnerDashboardScreen` with analytics
   - Create `ManagerDashboardScreen`, `StaffDashboardScreen`, `EmployeeDashboardScreen`

3. **Navigation Enhancement**
   - Update `MainLayout` with role-based bottom navigation
   - Implement route protection middleware

### Phase 3: Feature Modules (Week 3-4)

1. **Enhanced Order Management**
   ```
   /lib/screens/orders/
   ├── order_list_screen.dart       # Filterable order list
   ├── order_details_screen.dart    # Full order details with timeline
   ├── order_create_screen.dart     # Multi-step order creation
   └── widgets/
       ├── order_status_timeline.dart
       ├── order_filters_panel.dart
       └── order_summary_card.dart
   ```

2. **Multi-Warehouse Stock Management**
   ```
   /lib/screens/warehouse/
   ├── warehouse_selector_screen.dart
   ├── stock_transfer_screen.dart
   ├── transfer_approval_screen.dart
   └── widgets/
       ├── warehouse_card.dart
       ├── transfer_form.dart
       └── stock_movement_timeline.dart
   ```

3. **Employee Management System**
   ```
   /lib/screens/employees/
   ├── employee_list_screen.dart
   ├── attendance_tracking_screen.dart
   ├── performance_dashboard_screen.dart
   └── widgets/
       ├── gps_attendance_widget.dart
       ├── employee_performance_chart.dart
       └── shift_calendar.dart
   ```

### Phase 4: Advanced Features (Week 5-6)

1. **Production Management**
   - Material requirement planning
   - Production scheduling interface
   - Quality control workflows

2. **Financial Management**
   - Due book with payment tracking
   - Expense categorization and reporting
   - Purchase order management
   - Sales analytics and forecasting

3. **Advanced Reports & Analytics**
   - Custom report builder interface
   - PDF export with templates
   - Interactive data visualization
   - Scheduled report delivery

## Testing Strategy

### Unit Testing

```dart
// Example test for RoleProvider
testWidgets('RoleProvider should load permissions correctly', (tester) async {
  final roleProvider = RoleProvider();
  final mockUserProfile = UserProfile(/* ... */);
  
  roleProvider.initialize(mockUserProfile);
  
  expect(roleProvider.currentRole, UserRole.fromString(mockUserProfile.role));
  expect(roleProvider.hasPermission(Permission.viewOwnerDashboard), 
         isTrue || isFalse); // Based on role
});
```

### Integration Testing

```dart
// Example integration test for dashboard
testWidgets('Owner dashboard displays all required widgets', (tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RoleProvider>(create: (_) => mockRoleProvider),
        // ... other providers
      ],
      child: MaterialApp(home: OwnerDashboardScreen()),
    ),
  );
  
  expect(find.text('Business Overview'), findsOneWidget);
  expect(find.text('Key Performance Indicators'), findsOneWidget);
  expect(find.byType(MetricCard), findsNWidgets(4));
});
```

## Performance Considerations

### Optimization Strategies

1. **Lazy Loading**: Dashboard widgets load data progressively
2. **Image Caching**: Product images cached offline using `cached_network_image`
3. **Database Optimization**: Indexed queries and pagination for large datasets
4. **Memory Management**: Proper disposal of controllers and subscriptions

### Offline Support

1. **Data Synchronization**: Enhanced sync service handles role-based data
2. **Local Storage**: Hive adapters for new models (Warehouse, Employee, etc.)
3. **Conflict Resolution**: Last-write-wins with timestamp comparison
4. **Queue Management**: Pending actions prioritized by user role

## Security Implementation

### Permission Enforcement

```dart
// Server-side RLS policy examples (Supabase)
CREATE POLICY "Users can view warehouses based on role" ON warehouses
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE user_profiles.id = auth.uid() 
    AND (user_profiles.role IN ('owner', 'manager') 
         OR user_profiles.warehouse_id = warehouses.id)
  )
);
```

### Client-Side Security

1. **Route Protection**: Role-based navigation guards
2. **UI Hiding**: Sensitive data hidden based on permissions
3. **API Validation**: Server-side permission checks
4. **Token Management**: Secure JWT handling with refresh

This implementation guide provides a complete roadmap for transforming the existing FurniTrack app into a comprehensive, role-based furniture management system with modern UI, offline capabilities, and enterprise-grade features.