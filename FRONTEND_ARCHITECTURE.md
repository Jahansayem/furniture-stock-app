# FurniShop Manager - Complete Frontend Architecture

## Current State Analysis

### ✅ Existing Strong Foundation
- **State Management**: Provider pattern with 8 providers (Auth, Product, Stock, Notification, etc.)
- **Navigation**: GoRouter with ShellRoute for authenticated screens
- **Theme System**: Professional Material Design 3 with both Orange & Blue themes
- **Offline Support**: Hive storage + SyncService for offline-first architecture
- **Core Services**: OneSignal, Connectivity, GPS location services
- **Charts**: fl_chart integration for analytics

### 🔧 Current Limitations (To Address)
- Basic role system (needs role-based UI/navigation)
- Limited screen hierarchy (needs warehouse, employee, financial modules)
- Simple navigation (needs role-specific bottom nav)
- No permission system integration
- Missing production/material management screens
- No PDF export functionality

## Complete Screen Architecture

### 1. Authentication & Role Management
```
/auth/
├── login_screen.dart ✅ (Enhanced for role selection)
├── register_screen.dart ✅ (Role-based registration)
├── role_selection_screen.dart 🆕
└── forgot_password_screen.dart 🆕
```

### 2. Dashboard System (Role-Based)
```
/dashboard/
├── owner_dashboard.dart 🆕 (Complete analytics & KPIs)
├── manager_dashboard.dart 🆕 (Operational metrics)
├── staff_dashboard.dart 🆕 (Task-focused view)
├── employee_dashboard.dart 🆕 (Attendance & tasks)
└── shared/
    ├── dashboard_widgets.dart 🆕 (Reusable widgets)
    ├── kpi_card.dart 🆕
    ├── quick_actions_grid.dart 🆕
    └── activity_timeline.dart 🆕
```

### 3. Enhanced Order Management
```
/orders/
├── order_list_screen.dart 🆕 (Replace basic order management)
├── order_details_screen.dart 🆕
├── order_create_screen.dart 🆕
├── order_edit_screen.dart 🆕
├── order_tracking_screen.dart 🆕
├── batch_order_screen.dart 🆕
└── widgets/
    ├── order_status_chip.dart 🆕
    ├── order_timeline.dart 🆕
    └── order_filters.dart 🆕
```

### 4. Multi-Warehouse Stock Management
```
/stock/
├── stock_overview_screen.dart ✅ (Enhanced with warehouse filters)
├── warehouse_selection_screen.dart 🆕
├── warehouse_details_screen.dart 🆕
├── stock_transfer_screen.dart 🆕 (Enhanced from movement)
├── stock_adjustment_screen.dart 🆕
├── low_stock_alerts_screen.dart 🆕
├── stock_reports_screen.dart 🆕
└── widgets/
    ├── warehouse_card.dart 🆕
    ├── stock_level_indicator.dart 🆕
    ├── transfer_form.dart 🆕
    └── stock_timeline.dart 🆕
```

### 5. Employee Management System
```
/employees/
├── employee_list_screen.dart 🆕
├── employee_details_screen.dart 🆕
├── employee_add_screen.dart 🆕
├── employee_edit_screen.dart 🆕
├── attendance_screen.dart 🆕
├── attendance_history_screen.dart 🆕
├── employee_performance_screen.dart 🆕
├── shift_management_screen.dart 🆕
└── widgets/
    ├── employee_card.dart 🆕
    ├── attendance_map.dart 🆕
    ├── gps_check_in_widget.dart 🆕
    └── performance_metrics.dart 🆕
```

### 6. Production & Material Management
```
/production/
├── production_overview_screen.dart 🆕
├── production_order_screen.dart 🆕
├── material_list_screen.dart 🆕
├── material_request_screen.dart 🆕
├── production_schedule_screen.dart 🆕
├── quality_control_screen.dart 🆕
└── widgets/
    ├── production_status_card.dart 🆕
    ├── material_requirement_list.dart 🆕
    ├── production_timeline.dart 🆕
    └── quality_checklist.dart 🆕
```

### 7. Financial Management Modules
```
/finance/
├── finance_overview_screen.dart 🆕
├── due_book_screen.dart 🆕
├── expense_book_screen.dart 🆕
├── purchase_book_screen.dart 🆕
├── sales_book_screen.dart 🆕
├── payment_tracking_screen.dart 🆕
├── financial_reports_screen.dart 🆕
└── widgets/
    ├── financial_summary_card.dart 🆕
    ├── transaction_list.dart 🆕
    ├── payment_status_chip.dart 🆕
    └── financial_charts.dart 🆕
```

### 8. Enhanced Reports & Analytics
```
/reports/
├── reports_screen.dart ✅ (Enhanced with PDF export)
├── sales_reports_screen.dart 🆕
├── inventory_reports_screen.dart 🆕
├── employee_reports_screen.dart 🆕
├── financial_reports_screen.dart 🆕
├── custom_report_builder.dart 🆕
└── widgets/
    ├── report_filter_panel.dart 🆕
    ├── chart_selector.dart 🆕
    ├── pdf_preview_screen.dart 🆕
    └── export_options.dart 🆕
```

### 9. Settings & Configuration
```
/settings/
├── settings_screen.dart 🆕
├── role_permissions_screen.dart 🆕
├── warehouse_config_screen.dart 🆕
├── notification_settings_screen.dart 🆕
├── backup_settings_screen.dart 🆕
├── theme_settings_screen.dart 🆕
└── widgets/
    ├── permission_matrix.dart 🆕
    ├── setting_tile.dart 🆕
    └── config_form.dart 🆕
```

## Enhanced Provider Architecture

### New State Management Providers

```dart
// Role & Permission Management
class RoleProvider extends ChangeNotifier {
  UserRole? currentRole;
  Map<String, bool> permissions;
  
  bool hasPermission(String permission);
  void updateRole(UserRole role);
  void loadPermissions();
}

// Warehouse Management
class WarehouseProvider extends ChangeNotifier {
  List<Warehouse> warehouses;
  Warehouse? selectedWarehouse;
  
  Future<void> fetchWarehouses();
  void selectWarehouse(Warehouse warehouse);
  Future<bool> transferStock(StockTransfer transfer);
}

// Employee Management  
class EmployeeProvider extends ChangeNotifier {
  List<Employee> employees;
  List<AttendanceRecord> attendanceRecords;
  
  Future<void> fetchEmployees();
  Future<bool> checkIn(String employeeId, Position location);
  Future<bool> checkOut(String employeeId, Position location);
  Future<void> fetchAttendance(DateTime date);
}

// Production Management
class ProductionProvider extends ChangeNotifier {
  List<ProductionOrder> productionOrders;
  List<Material> materials;
  List<ProductionSchedule> schedules;
  
  Future<void> fetchProductionData();
  Future<bool> createProductionOrder(ProductionOrder order);
  Future<bool> updateProductionStatus(String orderId, ProductionStatus status);
}

// Financial Management
class FinanceProvider extends ChangeNotifier {
  FinancialSummary? summary;
  List<Transaction> transactions;
  Map<String, List<Transaction>> bookData; // due, expense, purchase, sales
  
  Future<void> fetchFinancialData();
  Future<bool> addTransaction(Transaction transaction);
  FinancialSummary calculateSummary();
}

// Report & Export
class ReportProvider extends ChangeNotifier {
  List<ReportTemplate> templates;
  ReportData? currentReport;
  
  Future<ReportData> generateReport(ReportConfig config);
  Future<File> exportToPDF(ReportData report);
  Future<File> exportToExcel(ReportData report);
}
```

## Role-Based Navigation System

### Navigation Structure by Role

```dart
// Enhanced Navigation Configuration
class NavigationConfig {
  static Map<UserRole, List<NavigationItem>> getNavigationItems(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return [
          NavigationItem(icon: Icons.dashboard, label: 'Dashboard', route: '/owner-dashboard'),
          NavigationItem(icon: Icons.analytics, label: 'Analytics', route: '/reports'),
          NavigationItem(icon: Icons.people, label: 'Employees', route: '/employees'),
          NavigationItem(icon: Icons.account_balance, label: 'Finance', route: '/finance'),
          NavigationItem(icon: Icons.settings, label: 'Settings', route: '/settings'),
        ];
      
      case UserRole.manager:
        return [
          NavigationItem(icon: Icons.dashboard, label: 'Dashboard', route: '/manager-dashboard'),
          NavigationItem(icon: Icons.inventory, label: 'Inventory', route: '/stock'),
          NavigationItem(icon: Icons.assignment, label: 'Orders', route: '/orders'),
          NavigationItem(icon: Icons.people, label: 'Staff', route: '/employees'),
          NavigationItem(icon: Icons.bar_chart, label: 'Reports', route: '/reports'),
        ];
      
      case UserRole.staff:
        return [
          NavigationItem(icon: Icons.work, label: 'Tasks', route: '/staff-dashboard'),
          NavigationItem(icon: Icons.inventory_2, label: 'Stock', route: '/stock'),
          NavigationItem(icon: Icons.point_of_sale, label: 'Sales', route: '/sales'),
          NavigationItem(icon: Icons.swap_horiz, label: 'Transfer', route: '/stock/transfer'),
        ];
      
      case UserRole.employee:
        return [
          NavigationItem(icon: Icons.schedule, label: 'Attendance', route: '/attendance'),
          NavigationItem(icon: Icons.assignment, label: 'Tasks', route: '/employee-tasks'),
          NavigationItem(icon: Icons.factory, label: 'Production', route: '/production'),
          NavigationItem(icon: Icons.person, label: 'Profile', route: '/profile'),
        ];
    }
  }
}

// Enhanced Main Layout with Role Support
class MainLayout extends StatefulWidget {
  final Widget child;
  final UserRole userRole;
  
  // Dynamic navigation based on role
  List<NavigationItem> get navigationItems => 
    NavigationConfig.getNavigationItems(userRole);
}
```

## UI/UX Design System Enhancement

### Role-Based Interface Adaptations

```dart
// Adaptive UI Components
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserRole role;
  final String title;
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: _buildTitleForRole(role, title),
      actions: _buildActionsForRole(role),
      backgroundColor: _getColorForRole(role),
    );
  }
  
  List<Widget> _buildActionsForRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return [NotificationIcon(), SettingsIcon(), ProfileIcon()];
      case UserRole.manager:
        return [NotificationIcon(), ReportsIcon(), ProfileIcon()];
      case UserRole.staff:
        return [NotificationIcon(), ProfileIcon()];
      case UserRole.employee:
        return [AttendanceIcon(), ProfileIcon()];
    }
  }
}

// Role-Based Quick Actions
class QuickActionsGrid extends StatelessWidget {
  final UserRole role;
  
  @override
  Widget build(BuildContext context) {
    final actions = _getActionsForRole(role);
    return GridView.builder(
      itemCount: actions.length,
      itemBuilder: (context, index) => QuickActionCard(actions[index]),
    );
  }
  
  List<QuickAction> _getActionsForRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return [
          QuickAction('View Analytics', Icons.analytics, '/reports'),
          QuickAction('Employee Performance', Icons.people, '/employees/performance'),
          QuickAction('Financial Summary', Icons.account_balance, '/finance'),
          QuickAction('System Settings', Icons.settings, '/settings'),
        ];
      // ... other roles
    }
  }
}
```

### Modern Material Design 3 Components

```dart
// Enhanced Component Library
class ModernCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor?.withOpacity(0.2) ?? 
                 Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Status Indicators with Animation
class AnimatedStatusChip extends StatelessWidget {
  final String label;
  final StatusType status;
  final bool animate;
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: animate ? Duration(milliseconds: 300) : Duration.zero,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getColorForStatus(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getColorForStatus(status)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getColorForStatus(status),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: _getColorForStatus(status),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

## File Handling & Media Management

### Image & Document Processing

```dart
// Enhanced File Service
class FileService {
  // Image handling with compression
  static Future<File> compressImage(File image, {int quality = 80}) async {
    final bytes = await image.readAsBytes();
    final compressedBytes = await FlutterImageCompress.compressWithList(
      bytes,
      quality: quality,
      minWidth: 800,
      minHeight: 600,
    );
    
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await compressedFile.writeAsBytes(compressedBytes);
    
    return compressedFile;
  }
  
  // PDF generation for reports
  static Future<File> generateReportPDF(ReportData data) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        build: (context) => _buildPDFContent(data),
        header: (context) => _buildPDFHeader(data),
        footer: (context) => _buildPDFFooter(context),
      ),
    );
    
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    
    return file;
  }
  
  // Offline image caching
  static Future<void> cacheImagesOffline(List<String> imageUrls) async {
    final cacheManager = DefaultCacheManager();
    
    for (final url in imageUrls) {
      try {
        await cacheManager.downloadFile(url);
      } catch (e) {
        AppLogger.warning('Failed to cache image: $url');
      }
    }
  }
}

// PDF Viewer Component
class PDFViewerScreen extends StatelessWidget {
  final File pdfFile;
  final String title;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _sharePDF(pdfFile),
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _downloadPDF(pdfFile),
          ),
        ],
      ),
      body: PDFView(
        filePath: pdfFile.path,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
      ),
    );
  }
}
```

## GPS & Location Services Enhancement

### Advanced Location Features

```dart
// Enhanced Location Service
class LocationService {
  static const double ATTENDANCE_RADIUS = 100.0; // meters
  
  // Geofencing for attendance
  static Future<bool> isWithinWorkLocation(
    Position userLocation, 
    Position workLocation
  ) async {
    final distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      workLocation.latitude,
      workLocation.longitude,
    );
    
    return distance <= ATTENDANCE_RADIUS;
  }
  
  // Background location tracking
  static Future<void> startLocationTracking() async {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Track every 10 meters
    );
    
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((position) {
      _handleLocationUpdate(position);
    });
  }
  
  // Offline GPS data storage
  static Future<void> storeLocationOffline(LocationData location) async {
    final offlineStorage = OfflineStorageService();
    await offlineStorage.storeLocationData(location);
  }
  
  // Distance calculation for reports
  static double calculateDailyDistance(List<Position> positions) {
    if (positions.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 1; i < positions.length; i++) {
      totalDistance += Geolocator.distanceBetween(
        positions[i - 1].latitude,
        positions[i - 1].longitude,
        positions[i].latitude,
        positions[i].longitude,
      );
    }
    
    return totalDistance / 1000.0; // Convert to kilometers
  }
}

// GPS Attendance Widget
class GPSAttendanceWidget extends StatefulWidget {
  @override
  _GPSAttendanceWidgetState createState() => _GPSAttendanceWidgetState();
}

class _GPSAttendanceWidgetState extends State<GPSAttendanceWidget> {
  Position? currentPosition;
  bool isCheckingLocation = false;
  AttendanceStatus status = AttendanceStatus.checkedOut;
  
  @override
  Widget build(BuildContext context) {
    return ModernCard(
      accentColor: _getStatusColor(status),
      child: Column(
        children: [
          _buildLocationStatus(),
          SizedBox(height: 16),
          _buildAttendanceButton(),
          if (currentPosition != null) ...[
            SizedBox(height: 12),
            _buildLocationDetails(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAttendanceButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isCheckingLocation ? null : _handleAttendanceAction,
        icon: isCheckingLocation 
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_getStatusIcon(status)),
        label: Text(_getStatusText(status)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getStatusColor(status),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
```

## Implementation Roadmap

### Phase 1: Foundation Enhancement (Week 1-2)
1. **Role-Based Provider System**
   - Implement RoleProvider with permission matrix
   - Update AuthProvider with role selection
   - Create role-based navigation configuration

2. **Enhanced Theme System**
   - Add role-specific color themes
   - Implement adaptive components
   - Create consistent design tokens

### Phase 2: Core Screen Development (Week 3-4)
1. **Dashboard Screens**
   - Owner/Manager/Staff/Employee dashboards
   - Role-specific widgets and metrics
   - Interactive analytics charts

2. **Enhanced Order Management**
   - Complete order lifecycle screens
   - Batch processing capabilities
   - Status tracking with notifications

### Phase 3: Advanced Features (Week 5-6)
1. **Multi-Warehouse System**
   - Warehouse selection and management
   - Inter-warehouse transfer workflows
   - Location-based stock visibility

2. **Employee Management**
   - GPS-based attendance system
   - Performance tracking
   - Shift management

### Phase 4: Specialized Modules (Week 7-8)
1. **Production Management**
   - Material requirement planning
   - Production scheduling
   - Quality control workflows

2. **Financial Management**
   - Complete book keeping system
   - Payment tracking
   - Financial reporting

### Phase 5: Reports & Analytics (Week 9-10)
1. **Advanced Reporting**
   - Custom report builder
   - PDF export functionality
   - Interactive data visualization

2. **System Configuration**
   - Permission management
   - System settings
   - Backup/restore functionality

This comprehensive frontend architecture provides:
- **Role-based interfaces** with appropriate permissions
- **Scalable component library** following Material Design 3
- **Offline-first architecture** with robust synchronization
- **Advanced analytics** with interactive charts and PDF export
- **GPS-enabled features** for employee attendance and tracking
- **Multi-warehouse support** with inter-location transfers
- **Complete financial management** with all required books
- **Production planning** with material management
- **Responsive design** that works across all device sizes

The architecture builds upon the existing strong foundation while addressing all PRD requirements for a complete furniture management system.