# FurniShop Manager - Complete Backend Integration Guide

## Overview

This guide provides comprehensive backend integration patterns for the enhanced FurniShop Manager with multi-warehouse support, role-based access control, production management, and advanced synchronization capabilities.

## 📋 Architecture Components

### Core Backend Services
- **Supabase PostgreSQL**: Primary database with advanced RLS policies
- **Real-time Subscriptions**: Live data synchronization across devices
- **External API Integrations**: Steadfast Courier, SMS, OneSignal
- **Offline-First Sync**: Advanced conflict resolution and bulk operations
- **Multi-Warehouse Support**: Granular access control per location

### Enhanced Features
- **Role-Based Security**: 8 distinct user roles with granular permissions
- **GPS-Based Attendance**: Location validation for employee check-in/out
- **Production Management**: Material requests and inventory tracking
- **Financial Due Book**: Customer balance and transaction management
- **Advanced Notifications**: Context-aware alerts with role-based filtering

## 🗄️ Database Schema Implementation

### 1. Execute Enhanced Schema

Run the complete database setup:

```sql
-- Execute in Supabase SQL Editor
\i ENHANCED_SUPABASE_SCHEMA.sql
\i RLS_POLICIES.sql
\i MIGRATION_STRATEGY.sql
```

### 2. Core Tables Structure

#### User Management & Roles
```sql
-- User roles with granular permissions
user_roles: role_name, display_name, permissions (JSONB)
user_profiles: enhanced with employee_id, warehouse_id, department

-- Employee management
employees: employee_code, department, warehouse_id, supervisor_id
attendance_records: GPS validation, work_hours calculation
```

#### Multi-Warehouse System
```sql
warehouses: warehouse_code, type, manager_id, capacity_sqft
stock_locations: warehouse_id reference for location hierarchy
```

#### Enhanced Order Management
```sql
orders: Steadfast integration fields, warehouse_id, profit tracking
order_items: production_cost, profit_margin (RLS protected)
```

#### Production & Materials
```sql
materials: material_code, supplier_info, reorder_level
material_requests: approval workflow, priority levels
material_request_items: quantity tracking
```

#### Financial System
```sql
transactions: comprehensive due book system
customer_balances: automated balance calculation
expenses: warehouse-based expense tracking
purchases: supplier management
```

### 3. Row Level Security (RLS) Policies

#### Multi-Level Access Control
```sql
-- Financial data protection (owner/admin only)
can_view_financial_data() -- Function-based policy
can_view_profit_margins() -- Restricted profit access

-- Warehouse-based visibility
can_access_warehouse(warehouse_id) -- Location-based access
user_warehouse_id() -- User's assigned warehouse
```

#### Role-Based Visibility
- **Owner**: Full system access including profit margins
- **Admin**: Administrative access without sensitive financial data
- **Manager**: Warehouse-specific management access
- **Sales Executive**: Order and customer management
- **Accountant**: Financial data access
- **Employee**: Limited operational access

## 🔄 Real-Time Integration Setup

### 1. Backend Integration Service

The `BackendIntegrationService` provides:

```dart
// Initialize real-time subscriptions based on user role
await backendService.initializeSubscriptions(userId, userRole, warehouseId);

// Register callbacks for real-time events
backendService.registerCallback('order_updated', (data) {
  // Handle order status changes
});

backendService.registerCallback('stock_updated', (data) {
  // Handle inventory changes
});
```

### 2. Subscription Patterns

#### Owner/Admin (All Data)
- Order status changes across all warehouses
- Stock level alerts system-wide
- Employee attendance monitoring
- Financial transaction notifications
- Material request approvals

#### Manager/Sales (Warehouse-Specific)
- Orders for assigned warehouse
- Stock alerts for managed inventory
- Team attendance records
- Customer notifications

#### Employee (Personal Data)
- Own attendance records
- Assigned order notifications
- Personal system alerts

## 🚚 External API Integrations

### 1. Steadfast Courier Integration

```dart
// Create shipment
final result = await backendService.createSteadfastShipment(
  orderId: orderId,
  orderData: orderData,
);

// Track shipment
final trackingData = await backendService.trackSteadfastShipment(consignmentId);
```

**Configuration Required:**
- API Key: `YOUR_STEADFAST_API_KEY`
- Secret Key: `YOUR_STEADFAST_SECRET_KEY`
- Webhook URL for delivery updates

### 2. SMS Service Integration

```dart
// Send order confirmation SMS
await backendService.sendSMS(
  phoneNumber: customer.phone,
  message: 'Your order #${orderNumber} has been confirmed',
  templateId: 'order_confirmation',
);
```

### 3. GPS Validation Service

```dart
// Validate employee location for attendance
final isValid = await backendService.validateGPSLocation(
  latitude: currentLat,
  longitude: currentLng,
  employeeId: employeeId,
);
```

## 📱 Offline-First Synchronization

### 1. Conflict Resolution Strategy

```sql
-- Detect conflicts before applying operations
SELECT * FROM detect_conflict(
  'orders',              -- table_name
  'order-123',          -- record_id  
  2,                    -- client_version
  '2024-01-15 10:30:00' -- client_timestamp
);

-- Resolve conflicts with different strategies
SELECT * FROM resolve_conflict(
  'operation-uuid-123',
  'client_wins'  -- or 'server_wins', 'merge', 'latest_timestamp'
);
```

### 2. Bulk Sync Operations

```dart
// Sync offline operations in bulk
final operations = [
  {
    'operation_id': 'uuid-1',
    'operation_type': 'create',
    'table_name': 'orders',
    'record_id': 'order-123',
    'client_timestamp': DateTime.now().toIso8601String(),
    'data': orderData,
  }
];

final results = await backendService.syncOfflineData(operations);
```

### 3. Data Consistency Validation

```sql
-- Check for data inconsistencies
SELECT * FROM validate_data_consistency();

-- Fix common issues automatically
SELECT * FROM fix_data_consistency_issues();
```

## 🔒 Security Implementation

### 1. Role-Based Access Control

```sql
-- Check user permissions in application
SELECT user_has_permission('view_financial_reports');
SELECT can_access_warehouse('warehouse-uuid');
SELECT can_view_profit_margins();
```

### 2. Audit Logging

All sensitive operations are automatically logged:

```sql
-- Audit logs for compliance
SELECT * FROM audit_logs 
WHERE table_name = 'transactions' 
AND action IN ('INSERT', 'UPDATE', 'DELETE');
```

### 3. Data Protection Policies

- **Financial Data**: Restricted to owner/admin/accountant roles
- **Profit Margins**: Owner-only access with RLS enforcement
- **Employee Salaries**: HR and self-access only
- **Cross-Warehouse Data**: Manager approval required

## 📊 Performance Optimization

### 1. Database Indexes

Comprehensive indexing for complex queries:

```sql
-- Multi-column indexes for filtering
CREATE INDEX idx_orders_complex ON orders(warehouse_id, order_status, order_type, created_at);
CREATE INDEX idx_attendance_employee_date ON attendance_records(employee_id, attendance_date);
```

### 2. Materialized Views

Pre-computed analytics views:

```sql
-- Sales summary with performance optimization
REFRESH MATERIALIZED VIEW CONCURRENTLY sales_summary;
REFRESH MATERIALIZED VIEW CONCURRENTLY stock_alerts;
```

### 3. Query Optimization

- Partition large tables by date ranges
- Use appropriate connection pooling
- Implement read replicas for reporting

## 🚀 Deployment Strategy

### 1. Database Deployment

```bash
# Execute schema updates
psql -h YOUR_SUPABASE_HOST -U postgres -d postgres -f ENHANCED_SUPABASE_SCHEMA.sql
psql -h YOUR_SUPABASE_HOST -U postgres -d postgres -f RLS_POLICIES.sql
psql -h YOUR_SUPABASE_HOST -U postgres -d postgres -f MIGRATION_STRATEGY.sql
```

### 2. Application Configuration

Update `.env` file:

```env
# Supabase Configuration (existing)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# External API Keys
STEADFAST_API_KEY=your-steadfast-api-key
STEADFAST_SECRET_KEY=your-steadfast-secret-key
SMS_API_KEY=your-sms-api-key
SMS_SENDER_ID=your-sender-id

# OneSignal (existing)
ONESIGNAL_APP_ID=your-onesignal-app-id
```

### 3. Flutter Application Updates

Register the backend integration service:

```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (existing)
  await Supabase.initialize(
    url: Environment.supabaseUrl,
    anonKey: Environment.supabaseAnonKey,
  );
  
  // Initialize backend integration service
  final backendService = BackendIntegrationService();
  
  runApp(MultiProvider(
    providers: [
      // Existing providers...
      ChangeNotifierProvider.value(value: backendService),
    ],
    child: MyApp(),
  ));
}
```

## 📈 Monitoring and Analytics

### 1. Real-Time Dashboards

Create views for real-time monitoring:

```sql
-- System performance view
CREATE VIEW system_health AS
SELECT 
  COUNT(*) as total_orders,
  COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '1 hour') as orders_last_hour,
  COUNT(*) FILTER (WHERE order_status = 'pending') as pending_orders,
  AVG(total_amount) as avg_order_value
FROM orders;
```

### 2. Business Intelligence

Pre-built analytics views:

```sql
-- Financial summary by warehouse
SELECT * FROM financial_summary 
WHERE transaction_date >= CURRENT_DATE - INTERVAL '30 days';

-- Employee performance tracking  
SELECT * FROM employee_attendance_summary
WHERE month = DATE_TRUNC('month', CURRENT_DATE);

-- Stock movement analysis
SELECT * FROM stock_alerts WHERE stock_status IN ('LOW', 'WARNING');
```

### 3. Notification Monitoring

Track notification delivery and engagement:

```sql
-- Notification analytics
SELECT 
  category,
  COUNT(*) as sent,
  COUNT(*) FILTER (WHERE is_read = true) as read,
  ROUND(COUNT(*) FILTER (WHERE is_read = true) * 100.0 / COUNT(*), 2) as read_rate
FROM notifications 
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY category;
```

## 🔧 Maintenance and Operations

### 1. Regular Maintenance Tasks

```sql
-- Weekly cleanup of old sync data
SELECT * FROM cleanup_old_sync_data(30);

-- Monthly data consistency check
SELECT * FROM validate_data_consistency();

-- Quarterly audit log cleanup
DELETE FROM audit_logs WHERE created_at < NOW() - INTERVAL '90 days';
```

### 2. Backup Strategy

```sql
-- Create data backup before major updates
SELECT * FROM create_data_backup('pre_update_backup');

-- Migrate legacy data if needed
SELECT * FROM migrate_legacy_data();
```

### 3. Performance Monitoring

```sql
-- Monitor slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;

-- Check index usage
SELECT schemaname, tablename, attname, n_distinct, correlation 
FROM pg_stats 
WHERE tablename IN ('orders', 'stocks', 'attendance_records');
```

## 🎯 Testing Strategy

### 1. Unit Tests

Test core business logic:

```dart
testWidgets('Backend integration service initializes correctly', (tester) async {
  final service = BackendIntegrationService();
  await service.initializeSubscriptions('user-id', 'admin', null);
  expect(service.isInitialized, isTrue);
});
```

### 2. Integration Tests

Test API integrations:

```dart
group('Steadfast Integration', () {
  test('creates shipment successfully', () async {
    final result = await backendService.createSteadfastShipment(
      orderId: 'test-order',
      orderData: mockOrderData,
    );
    expect(result['consignment_id'], isNotNull);
  });
});
```

### 3. Performance Tests

Load testing for sync operations:

```sql
-- Test bulk sync performance
SELECT * FROM bulk_sync_data(
  '[{"operation_id": "test-1", "operation_type": "create", ...}]'::JSONB,
  'test-device',
  'test-user-uuid'::UUID
);
```

## ⚠️ Production Considerations

### 1. Security Checklist

- [ ] Enable RLS on all tables
- [ ] Validate API rate limits
- [ ] Implement proper error handling
- [ ] Set up monitoring alerts
- [ ] Configure backup schedules
- [ ] Test disaster recovery procedures

### 2. Scalability Planning

- **Database**: Plan for horizontal scaling with read replicas
- **API Limits**: Implement rate limiting and caching
- **Storage**: Configure automatic cleanup policies
- **Monitoring**: Set up comprehensive observability

### 3. Compliance Requirements

- **Data Privacy**: Implement GDPR/privacy compliance
- **Financial Records**: Maintain audit trails for transactions
- **Employee Data**: Secure handling of personal information
- **Location Data**: GPS data privacy considerations

---

## 🎉 Implementation Summary

This comprehensive backend integration provides:

✅ **Enhanced Database Schema**: 15+ tables with advanced relationships  
✅ **Role-Based Security**: 8 user roles with granular permissions  
✅ **Multi-Warehouse Support**: Location-based access control  
✅ **Real-Time Synchronization**: Live updates across all devices  
✅ **External API Integration**: Steadfast, SMS, GPS validation  
✅ **Offline-First Architecture**: Advanced conflict resolution  
✅ **Production Management**: Material requests and inventory  
✅ **Financial Due Book**: Customer balance automation  
✅ **Performance Optimization**: Comprehensive indexing strategy  
✅ **Monitoring & Analytics**: Pre-built business intelligence views  

The system is designed for production deployment with comprehensive security, scalability, and maintainability considerations.