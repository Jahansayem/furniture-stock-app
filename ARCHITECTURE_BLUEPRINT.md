# FurniShop Manager - Complete System Architecture Blueprint

## Architecture Overview

### Core Design Principles
- **Offline-First**: All operations work offline with automatic sync when online
- **Role-Based Access**: 5-tier permission system with granular controls
- **Real-Time Updates**: Live data synchronization using Supabase subscriptions
- **Scalable Design**: Supports 50+ concurrent users with optimized queries
- **Security-First**: Row-Level Security (RLS) with comprehensive data protection
- **Multi-Channel**: Supports online COD, offline sales, and courier integration

### Technology Stack
- **Frontend**: Flutter 3.32+ with Provider state management
- **Backend**: Supabase (PostgreSQL) with real-time subscriptions
- **Storage**: Hive (offline), Supabase Storage (files)
- **API Integrations**: Steadfast Courier, SMS services
- **Analytics**: fl_chart for reports and dashboards

---

## 1. Enhanced Database Schema

### 1.1 User Management & Roles
```sql
-- Enhanced user_profiles with role-based permissions
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS
    role_permissions JSONB DEFAULT '{}',
    department TEXT DEFAULT 'general',
    manager_id UUID REFERENCES user_profiles(id),
    location_access TEXT[] DEFAULT '{}',
    feature_access TEXT[] DEFAULT '{}',
    salary DECIMAL(10,2),
    hire_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    last_activity TIMESTAMPTZ,
    login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMPTZ;

-- Create roles hierarchy table
CREATE TABLE user_roles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    role_name TEXT UNIQUE NOT NULL,
    role_level INTEGER NOT NULL, -- 1=Super Admin, 2=Admin, 3=Manager, 4=Staff, 5=Viewer
    permissions JSONB NOT NULL,
    can_manage_roles TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default roles
INSERT INTO user_roles (role_name, role_level, permissions, can_manage_roles) VALUES
('super_admin', 1, '{"all": true}', '{"admin", "manager", "staff", "viewer"}'),
('admin', 2, '{"products": {"create": true, "read": true, "update": true, "delete": true}, "orders": {"all": true}, "reports": {"all": true}, "users": {"read": true, "update": true}}', '{"manager", "staff", "viewer"}'),
('manager', 3, '{"products": {"read": true, "update": true}, "orders": {"create": true, "read": true, "update": true}, "reports": {"read": true}, "stock": {"all": true}}', '{"staff", "viewer"}'),
('staff', 4, '{"products": {"read": true}, "orders": {"create": true, "read": true}, "stock": {"read": true, "update": true}}', '{}'),
('viewer', 5, '{"products": {"read": true}, "orders": {"read": true}, "stock": {"read": true}, "reports": {"read": true}}', '{}');
```

### 1.2 Enhanced Product & Inventory Management
```sql
-- Enhanced products table with categories and variants
ALTER TABLE products ADD COLUMN IF NOT EXISTS
    category_id UUID,
    brand TEXT,
    model TEXT,
    sku TEXT UNIQUE,
    dimensions JSONB, -- {width, height, depth, weight}
    materials TEXT[],
    colors TEXT[],
    finish_options TEXT[],
    warranty_period INTEGER, -- months
    supplier_info JSONB,
    manufacturing_cost DECIMAL(10,2),
    margin_percentage DECIMAL(5,2),
    status TEXT CHECK (status IN ('active', 'discontinued', 'draft')) DEFAULT 'active',
    seo_tags TEXT[],
    is_featured BOOLEAN DEFAULT FALSE,
    bulk_discount_rules JSONB;

-- Product categories
CREATE TABLE product_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id UUID REFERENCES product_categories(id),
    description TEXT,
    image_url TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Product variants (different colors, sizes, etc.)
CREATE TABLE product_variants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    variant_name TEXT NOT NULL,
    sku TEXT UNIQUE,
    price_adjustment DECIMAL(10,2) DEFAULT 0,
    attributes JSONB, -- color, size, material variations
    image_urls TEXT[],
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 1.3 Advanced Order Management
```sql
-- Enhanced orders table (replacing basic sales)
CREATE TABLE orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_number TEXT UNIQUE NOT NULL,
    customer_id UUID,
    order_type TEXT CHECK (order_type IN ('online_cod', 'offline', 'wholesale', 'showroom')) NOT NULL,
    status TEXT CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')) DEFAULT 'pending',
    
    -- Customer information
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_email TEXT,
    customer_address TEXT NOT NULL,
    customer_location POINT, -- latitude, longitude
    
    -- Financial details
    subtotal DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    delivery_charge DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    advance_payment DECIMAL(10,2) DEFAULT 0,
    due_amount DECIMAL(10,2) DEFAULT 0,
    
    -- Delivery information
    delivery_date DATE,
    delivery_time_slot TEXT,
    special_instructions TEXT,
    courier_service TEXT,
    consignment_id TEXT,
    tracking_code TEXT,
    
    -- Workflow management
    assigned_to UUID REFERENCES user_profiles(id),
    priority TEXT CHECK (priority IN ('low', 'normal', 'high', 'urgent')) DEFAULT 'normal',
    source TEXT, -- website, phone, showroom, etc.
    notes TEXT,
    
    -- Audit trail
    created_by UUID REFERENCES user_profiles(id),
    updated_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Order items with detailed tracking
CREATE TABLE order_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    product_variant_id UUID REFERENCES product_variants(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    product_snapshot JSONB, -- Store product details at time of order
    customization_details TEXT,
    production_status TEXT DEFAULT 'pending',
    estimated_completion DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Order status history for tracking
CREATE TABLE order_status_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    from_status TEXT,
    to_status TEXT NOT NULL,
    changed_by UUID REFERENCES user_profiles(id),
    reason TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 1.4 Advanced Stock & Location Management
```sql
-- Enhanced stock locations with hierarchy
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS
    parent_location_id UUID REFERENCES stock_locations(id),
    location_code TEXT UNIQUE,
    manager_id UUID REFERENCES user_profiles(id),
    contact_phone TEXT,
    operating_hours JSONB,
    storage_capacity INTEGER,
    current_utilization INTEGER DEFAULT 0,
    location_coordinates POINT,
    is_active BOOLEAN DEFAULT TRUE,
    settings JSONB DEFAULT '{}';

-- Enhanced stocks with detailed tracking
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS
    reserved_quantity INTEGER DEFAULT 0,
    minimum_stock INTEGER DEFAULT 0,
    maximum_stock INTEGER DEFAULT 1000,
    reorder_point INTEGER DEFAULT 10,
    average_cost DECIMAL(10,2) DEFAULT 0,
    last_stock_take DATE,
    stock_value DECIMAL(12,2) DEFAULT 0;

-- Stock movements with detailed tracking
CREATE TABLE stock_movements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES products(id),
    product_variant_id UUID REFERENCES product_variants(id),
    location_id UUID REFERENCES stock_locations(id),
    movement_type TEXT CHECK (movement_type IN ('in', 'out', 'transfer', 'adjustment', 'return')) NOT NULL,
    quantity INTEGER NOT NULL,
    reference_type TEXT, -- order, purchase, transfer, adjustment
    reference_id UUID,
    unit_cost DECIMAL(10,2),
    total_cost DECIMAL(10,2),
    reason TEXT,
    batch_number TEXT,
    expiry_date DATE,
    performed_by UUID REFERENCES user_profiles(id),
    approved_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Stock reservations for pending orders
CREATE TABLE stock_reservations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES products(id),
    product_variant_id UUID REFERENCES product_variants(id),
    location_id UUID REFERENCES stock_locations(id),
    order_id UUID REFERENCES orders(id),
    quantity INTEGER NOT NULL,
    reserved_until TIMESTAMPTZ NOT NULL,
    created_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 1.5 Customer Relationship Management
```sql
-- Customer management
CREATE TABLE customers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_code TEXT UNIQUE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    address TEXT,
    location POINT,
    customer_type TEXT CHECK (customer_type IN ('individual', 'business', 'wholesale')) DEFAULT 'individual',
    credit_limit DECIMAL(10,2) DEFAULT 0,
    current_balance DECIMAL(10,2) DEFAULT 0,
    preferred_delivery_time TEXT,
    notes TEXT,
    tags TEXT[],
    source TEXT, -- how they found us
    assigned_sales_rep UUID REFERENCES user_profiles(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customer purchase history and analytics
CREATE TABLE customer_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0,
    average_order_value DECIMAL(10,2) DEFAULT 0,
    last_order_date TIMESTAMPTZ,
    favorite_categories TEXT[],
    loyalty_score INTEGER DEFAULT 0,
    churn_risk TEXT CHECK (churn_risk IN ('low', 'medium', 'high')) DEFAULT 'low',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 1.6 Financial Management
```sql
-- Payment tracking
CREATE TABLE payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id),
    customer_id UUID REFERENCES customers(id),
    payment_type TEXT CHECK (payment_type IN ('cash', 'card', 'bank_transfer', 'mobile_banking', 'cod')) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method_details JSONB, -- card last 4 digits, bank info, etc.
    transaction_id TEXT,
    payment_status TEXT CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')) DEFAULT 'pending',
    payment_date TIMESTAMPTZ DEFAULT NOW(),
    processed_by UUID REFERENCES user_profiles(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Expense tracking
CREATE TABLE expenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    expense_date DATE NOT NULL,
    receipt_url TEXT,
    approved_by UUID REFERENCES user_profiles(id),
    status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    created_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 1.7 Courier & Logistics Integration
```sql
-- Courier service management
CREATE TABLE courier_services (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_name TEXT UNIQUE NOT NULL,
    api_endpoint TEXT,
    api_credentials JSONB,
    supported_areas TEXT[],
    pricing_rules JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Delivery tracking
CREATE TABLE deliveries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id),
    courier_service_id UUID REFERENCES courier_services(id),
    consignment_id TEXT UNIQUE,
    tracking_code TEXT,
    delivery_status TEXT,
    pickup_date DATE,
    estimated_delivery DATE,
    actual_delivery_date DATE,
    delivery_charge DECIMAL(10,2),
    cod_amount DECIMAL(10,2),
    delivery_address TEXT,
    recipient_phone TEXT,
    delivery_notes TEXT,
    proof_of_delivery TEXT, -- image URL or signature
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 2. Role-Based Access Control (RBAC) Architecture

### 2.1 Permission Matrix
```dart
class PermissionLevel {
  static const int SUPER_ADMIN = 1;
  static const int ADMIN = 2;
  static const int MANAGER = 3;
  static const int STAFF = 4;
  static const int VIEWER = 5;
}

class Permissions {
  // Module-based permissions
  static const Map<String, Map<int, List<String>>> MODULE_PERMISSIONS = {
    'products': {
      1: ['create', 'read', 'update', 'delete', 'bulk_import', 'export'],
      2: ['create', 'read', 'update', 'delete', 'export'],
      3: ['read', 'update', 'export'],
      4: ['read', 'update_stock'],
      5: ['read'],
    },
    'orders': {
      1: ['create', 'read', 'update', 'delete', 'cancel', 'refund', 'export'],
      2: ['create', 'read', 'update', 'cancel', 'refund', 'export'],
      3: ['create', 'read', 'update', 'export'],
      4: ['create', 'read', 'update_own'],
      5: ['read'],
    },
    'customers': {
      1: ['create', 'read', 'update', 'delete', 'export'],
      2: ['create', 'read', 'update', 'export'],
      3: ['create', 'read', 'update'],
      4: ['read', 'create'],
      5: ['read'],
    },
    'reports': {
      1: ['all_reports', 'financial', 'inventory', 'sales', 'user_activity'],
      2: ['financial', 'inventory', 'sales'],
      3: ['inventory', 'sales', 'own_team'],
      4: ['basic_sales'],
      5: ['basic_inventory'],
    },
    'settings': {
      1: ['system', 'users', 'roles', 'integrations'],
      2: ['users', 'basic_settings'],
      3: ['location_settings'],
      4: [],
      5: [],
    }
  };
}
```

### 2.2 Permission Service Implementation
```dart
class PermissionService {
  static bool hasPermission(UserProfile user, String module, String action) {
    final userRole = _getUserRoleLevel(user.role);
    final modulePermissions = Permissions.MODULE_PERMISSIONS[module];
    
    if (modulePermissions == null) return false;
    
    final rolePermissions = modulePermissions[userRole];
    return rolePermissions?.contains(action) ?? false;
  }
  
  static bool canAccessLocation(UserProfile user, String locationId) {
    if (user.role == 'super_admin' || user.role == 'admin') return true;
    return user.locationAccess?.contains(locationId) ?? false;
  }
  
  static bool canManageUser(UserProfile manager, UserProfile targetUser) {
    final managerLevel = _getUserRoleLevel(manager.role);
    final targetLevel = _getUserRoleLevel(targetUser.role);
    return managerLevel < targetLevel;
  }
}
```

---

## 3. Real-Time Data Flow Architecture

### 3.1 Supabase Real-Time Subscriptions
```dart
class RealtimeManager {
  static final Map<String, RealtimeChannel> _channels = {};
  
  static void initializeSubscriptions(String userId, String userRole) {
    // Orders real-time updates
    _channels['orders'] = supabase
        .channel('orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) => _handleOrderUpdate(payload),
        )
        .subscribe();
    
    // Stock level updates
    _channels['stocks'] = supabase
        .channel('stocks')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public', 
          table: 'stocks',
          callback: (payload) => _handleStockUpdate(payload),
        )
        .subscribe();
    
    // User-specific notifications
    if (userRole != 'viewer') {
      _channels['notifications'] = supabase
          .channel('notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) => _handleNotification(payload),
          )
          .subscribe();
    }
  }
  
  static void _handleOrderUpdate(PostgresChangePayload payload) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.handleRealtimeUpdate(payload);
  }
  
  static void _handleStockUpdate(PostgresChangePayload payload) {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    stockProvider.handleRealtimeUpdate(payload);
  }
}
```

### 3.2 Event-Driven State Management
```dart
abstract class RealtimeProvider extends ChangeNotifier {
  void handleRealtimeUpdate(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _handleInsert(payload.newRecord);
        break;
      case PostgresChangeEvent.update:
        _handleUpdate(payload.oldRecord, payload.newRecord);
        break;
      case PostgresChangeEvent.delete:
        _handleDelete(payload.oldRecord);
        break;
    }
    notifyListeners();
  }
  
  void _handleInsert(Map<String, dynamic> record);
  void _handleUpdate(Map<String, dynamic> oldRecord, Map<String, dynamic> newRecord);
  void _handleDelete(Map<String, dynamic> record);
}
```

---

## 4. Offline-First Sync Architecture

### 4.1 Enhanced Sync Strategy
```dart
class EnhancedSyncService extends ChangeNotifier {
  // Priority-based sync queues
  static const List<String> SYNC_PRIORITIES = ['critical', 'high', 'normal', 'low'];
  
  Future<bool> syncWithPriority() async {
    if (!connectivity.isOnline) return false;
    
    for (final priority in SYNC_PRIORITIES) {
      final actions = await OfflineStorageService.getPendingActionsByPriority(priority);
      
      for (final action in actions) {
        try {
          await _processActionWithRetry(action);
          await OfflineStorageService.removePendingAction(action['id']);
        } catch (e) {
          if (priority == 'critical') {
            // Critical actions must succeed - retry with exponential backoff
            await _scheduleRetry(action, priority);
          }
          // Log but continue with other actions
        }
      }
    }
    
    // Bi-directional sync
    await _downloadIncrementalUpdates();
    await _uploadLocalChanges();
    
    return true;
  }
  
  Future<void> _downloadIncrementalUpdates() async {
    final lastSync = await OfflineStorageService.getLastSyncTimestamp();
    
    // Download only changes since last sync
    final updates = await supabase.rpc('get_incremental_updates', params: {
      'since_timestamp': lastSync.toIso8601String(),
      'user_permissions': await _getUserPermissions(),
    });
    
    await OfflineStorageService.mergeIncrementalUpdates(updates);
  }
}
```

### 4.2 Conflict Resolution Strategy
```dart
class ConflictResolution {
  static Future<Map<String, dynamic>> resolveConflict(
    String entityType,
    Map<String, dynamic> localRecord,
    Map<String, dynamic> serverRecord,
  ) async {
    switch (entityType) {
      case 'orders':
        return _resolveOrderConflict(localRecord, serverRecord);
      case 'products':
        return _resolveProductConflict(localRecord, serverRecord);
      case 'stocks':
        return _resolveStockConflict(localRecord, serverRecord);
      default:
        // Default: server wins for unknown entities
        return serverRecord;
    }
  }
  
  static Map<String, dynamic> _resolveStockConflict(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    // For stock: sum the movements, don't overwrite
    final localQuantity = local['quantity'] as int;
    final serverQuantity = server['quantity'] as int;
    final localMovements = local['pending_movements'] as List? ?? [];
    
    // Apply local movements to server state
    int adjustedQuantity = serverQuantity;
    for (final movement in localMovements) {
      adjustedQuantity += movement['quantity'] as int;
    }
    
    return {
      ...server,
      'quantity': adjustedQuantity,
      'conflict_resolved': true,
      'resolution_method': 'movement_based',
    };
  }
}
```

---

## 5. File Management & PDF Generation

### 5.1 Document Generation Service
```dart
class DocumentService {
  static Future<String> generateOrderPDF(Order order) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        header: (context) => _buildPDFHeader(),
        footer: (context) => _buildPDFFooter(context),
        build: (context) => [
          _buildOrderDetails(order),
          pw.SizedBox(height: 20),
          _buildCustomerInfo(order),
          pw.SizedBox(height: 20),
          _buildOrderItems(order.items),
          pw.SizedBox(height: 20),
          _buildPricingSummary(order),
          if (order.notes?.isNotEmpty == true) ...[
            pw.SizedBox(height: 20),
            _buildNotes(order.notes!),
          ],
        ],
      ),
    );
    
    return await _savePDF(pdf, 'order_${order.orderNumber}');
  }
  
  static Future<String> generateInventoryReport(
    List<Product> products,
    Map<String, int> stockLevels,
  ) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildInventoryHeader(),
          pw.SizedBox(height: 20),
          _buildInventoryTable(products, stockLevels),
          pw.SizedBox(height: 20),
          _buildInventorySummary(products, stockLevels),
        ],
      ),
    );
    
    return await _savePDF(pdf, 'inventory_${DateTime.now().millisecondsSinceEpoch}');
  }
}
```

### 5.2 File Storage Strategy
```dart
class FileStorageService {
  static const Map<String, String> STORAGE_BUCKETS = {
    'product_images': 'product-images',
    'order_documents': 'order-documents',
    'reports': 'reports',
    'user_uploads': 'user-uploads',
    'backup_files': 'backups',
  };
  
  static Future<String> uploadFile(
    String bucketType,
    File file,
    String fileName, {
    String? folder,
  }) async {
    final bucket = STORAGE_BUCKETS[bucketType];
    if (bucket == null) throw Exception('Unknown bucket type: $bucketType');
    
    final path = folder != null ? '$folder/$fileName' : fileName;
    
    await supabase.storage
        .from(bucket)
        .upload(path, file, fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: false,
        ));
    
    return supabase.storage.from(bucket).getPublicUrl(path);
  }
  
  static Future<void> optimizeImage(File imageFile) async {
    // Compress and resize images for optimal storage
    final image = img.decodeImage(imageFile.readAsBytesSync())!;
    final resized = img.copyResize(image, width: 800);
    final compressed = img.encodeJpg(resized, quality: 85);
    
    await imageFile.writeAsBytes(compressed);
  }
}
```

---

## 6. Performance & Scalability Optimizations

### 6.1 Database Indexing Strategy
```sql
-- Performance indexes for high-traffic queries
CREATE INDEX CONCURRENTLY idx_orders_status_date ON orders(status, created_at DESC);
CREATE INDEX CONCURRENTLY idx_orders_customer_phone ON orders(customer_phone);
CREATE INDEX CONCURRENTLY idx_orders_assigned_user ON orders(assigned_to, status);

CREATE INDEX CONCURRENTLY idx_stocks_product_location ON stocks(product_id, location_id);
CREATE INDEX CONCURRENTLY idx_stocks_low_stock ON stocks(quantity) WHERE quantity <= (SELECT minimum_stock FROM stocks s2 WHERE s2.id = stocks.id);

CREATE INDEX CONCURRENTLY idx_order_items_product ON order_items(product_id);
CREATE INDEX CONCURRENTLY idx_stock_movements_product_date ON stock_movements(product_id, created_at DESC);

-- Composite indexes for complex queries
CREATE INDEX CONCURRENTLY idx_orders_compound ON orders(status, order_type, created_at DESC);
CREATE INDEX CONCURRENTLY idx_payments_order_status ON payments(order_id, payment_status);

-- Text search indexes
CREATE INDEX CONCURRENTLY idx_products_search ON products USING gin(to_tsvector('english', product_name || ' ' || COALESCE(description, '')));
CREATE INDEX CONCURRENTLY idx_customers_search ON customers USING gin(to_tsvector('english', name || ' ' || phone));
```

### 6.2 Query Optimization Patterns
```dart
class OptimizedQueries {
  // Use pagination with cursor-based approach
  static Future<List<Order>> getOrdersPage({
    String? cursor,
    int limit = 50,
    String? status,
    String? search,
  }) async {
    var query = supabase
        .from('orders')
        .select('''
          id, order_number, customer_name, customer_phone, 
          total_amount, status, created_at,
          order_items(id, product_id, quantity, unit_price),
          customers(id, name, phone)
        ''')
        .order('created_at', ascending: false)
        .limit(limit);
    
    if (cursor != null) {
      query = query.lt('created_at', cursor);
    }
    
    if (status != null) {
      query = query.eq('status', status);
    }
    
    if (search != null) {
      query = query.or('customer_name.ilike.%$search%,customer_phone.ilike.%$search%');
    }
    
    final response = await query;
    return response.map((json) => Order.fromJson(json)).toList();
  }
  
  // Use materialized views for complex reports
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await supabase.rpc('get_dashboard_stats');
    return response;
  }
}
```

### 6.3 Caching Strategy
```dart
class CacheManager {
  static final Map<String, CachedData> _cache = {};
  static const Duration DEFAULT_TTL = Duration(minutes: 5);
  
  static Future<T?> get<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
  }) async {
    final cached = _cache[key];
    
    if (cached != null && !cached.isExpired) {
      return cached.data as T;
    }
    
    final data = await fetcher();
    _cache[key] = CachedData(
      data: data,
      expiry: DateTime.now().add(ttl ?? DEFAULT_TTL),
    );
    
    return data;
  }
  
  static void invalidate(String key) {
    _cache.remove(key);
  }
  
  static void invalidatePattern(String pattern) {
    final regex = RegExp(pattern);
    _cache.removeWhere((key, value) => regex.hasMatch(key));
  }
}

class CachedData {
  final dynamic data;
  final DateTime expiry;
  
  CachedData({required this.data, required this.expiry});
  
  bool get isExpired => DateTime.now().isAfter(expiry);
}
```

---

## 7. Security Architecture

### 7.1 Row Level Security Policies
```sql
-- Orders security - users can only see orders they're authorized for
CREATE POLICY "order_access_policy" ON orders
FOR ALL TO authenticated
USING (
  -- Super admins and admins can see all
  (SELECT role FROM user_profiles WHERE id = auth.uid()) IN ('super_admin', 'admin')
  OR
  -- Managers can see orders from their locations
  (SELECT role FROM user_profiles WHERE id = auth.uid()) = 'manager' 
  AND EXISTS (
    SELECT 1 FROM user_profiles up 
    WHERE up.id = auth.uid() 
    AND (location_access @> ARRAY[orders.location_id::text] OR location_access = '{}')
  )
  OR
  -- Staff can see orders assigned to them
  assigned_to = auth.uid()
  OR
  -- Users can see orders they created
  created_by = auth.uid()
);

-- Stock access based on location permissions
CREATE POLICY "stock_location_access" ON stocks
FOR ALL TO authenticated
USING (
  (SELECT role FROM user_profiles WHERE id = auth.uid()) IN ('super_admin', 'admin')
  OR
  EXISTS (
    SELECT 1 FROM user_profiles up 
    WHERE up.id = auth.uid() 
    AND (
      up.location_access @> ARRAY[stocks.location_id::text] 
      OR up.location_access = '{}'
      OR up.role IN ('manager', 'staff')
    )
  )
);
```

### 7.2 Data Encryption & Validation
```dart
class SecurityService {
  static String encryptSensitiveData(String data) {
    final key = encrypt.Key.fromSecureRandom(32);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    return encrypter.encrypt(data, iv: iv).base64;
  }
  
  static bool validatePhoneNumber(String phone) {
    return RegExp(r'^\+?[1-9]\d{10}$').hasMatch(phone);
  }
  
  static bool validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>"\']'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
```

---

## 8. API Integration Patterns

### 8.1 Steadfast Courier Enhanced Integration
```dart
class EnhancedCourierService extends SteadFastService {
  // Webhook handler for delivery status updates
  static Future<void> handleWebhook(Map<String, dynamic> payload) async {
    try {
      final consignmentId = payload['consignment_id'];
      final status = payload['delivery_status'];
      final deliveryDate = payload['delivery_date'];
      
      // Update local database
      await supabase
          .from('deliveries')
          .update({
            'delivery_status': status,
            'actual_delivery_date': deliveryDate,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('consignment_id', consignmentId);
      
      // Update order status if delivered
      if (status == 'delivered') {
        final delivery = await supabase
            .from('deliveries')
            .select('order_id')
            .eq('consignment_id', consignmentId)
            .single();
        
        await supabase
            .from('orders')
            .update({'status': 'delivered'})
            .eq('id', delivery['order_id']);
      }
      
      // Send notification to relevant users
      await _notifyStatusUpdate(consignmentId, status);
      
    } catch (e) {
      AppLogger.error('Webhook processing failed', error: e);
    }
  }
  
  // Bulk order processing
  static Future<List<SteadFastOrderResponse>> processBulkOrders(
    List<Map<String, dynamic>> orders,
  ) async {
    final results = <SteadFastOrderResponse>[];
    
    // Process in batches of 10
    for (int i = 0; i < orders.length; i += 10) {
      final batch = orders.skip(i).take(10);
      final batchResults = await Future.wait(
        batch.map((order) => createOrder(
          invoice: order['invoice'],
          recipientName: order['recipient_name'],
          recipientPhone: order['recipient_phone'],
          recipientAddress: order['recipient_address'],
          codAmount: order['cod_amount'],
          notes: order['notes'],
        )),
      );
      
      results.addAll(batchResults.where((r) => r != null).cast());
      
      // Rate limiting - wait between batches
      if (i + 10 < orders.length) {
        await Future.delayed(Duration(seconds: 2));
      }
    }
    
    return results;
  }
}
```

### 8.2 SMS Integration Service
```dart
class SMSService {
  static Future<bool> sendOrderConfirmation(Order order) async {
    final message = '''
অর্ডার নিশ্চিত হয়েছে!
অর্ডার নং: ${order.orderNumber}
পরিমাণ: ৳${order.totalAmount}
ডেলিভারি: ${order.estimatedDeliveryDate}
ট্র্যাক করুন: bit.ly/track${order.id}
-FurniShop
''';
    
    return await _sendSMS(order.customerPhone, message);
  }
  
  static Future<bool> sendDeliveryUpdate(Order order, String status) async {
    final statusMessages = {
      'shipped': 'আপনার অর্ডার পাঠানো হয়েছে',
      'out_for_delivery': 'আপনার অর্ডার ডেলিভারির জন্য বেরিয়েছে',
      'delivered': 'আপনার অর্ডার ডেলিভার হয়েছে',
    };
    
    final message = '''
${statusMessages[status]}
অর্ডার নং: ${order.orderNumber}
${order.trackingCode != null ? 'ট্র্যাকিং: ${order.trackingCode}' : ''}
-FurniShop
''';
    
    return await _sendSMS(order.customerPhone, message);
  }
  
  static Future<bool> _sendSMS(String phone, String message) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.sms.net.bd/sendsms'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'api_key': Environment.smsApiKey,
          'sender_id': Environment.smsSenderId,
          'message': message,
          'phone': phone,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('SMS sending failed', error: e);
      return false;
    }
  }
}
```

---

## 9. Implementation Patterns & Guidelines

### 9.1 Provider Architecture Enhancement
```dart
// Base provider with common functionality
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Template method pattern for consistent error handling
  Future<T?> executeWithErrorHandling<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    try {
      setLoading(true);
      clearError();
      
      final result = await operation();
      return result;
      
    } catch (e) {
      AppLogger.error('$operationName failed', error: e);
      setError('$operationName failed: ${e.toString()}');
      return null;
    } finally {
      setLoading(false);
    }
  }
}
```

### 9.2 Feature-Based Module Structure
```
lib/
├── features/
│   ├── authentication/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── services/
│   ├── inventory/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── services/
│   ├── orders/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── services/
│   └── reports/
│       ├── models/
│       ├── providers/
│       ├── screens/
│       └── services/
├── core/
│   ├── services/
│   ├── utils/
│   ├── constants/
│   └── config/
└── shared/
    ├── widgets/
    ├── theme/
    └── extensions/
```

---

## 10. Deployment & Monitoring Strategy

### 10.1 Environment Configuration
```yaml
# CI/CD Pipeline Configuration
stages:
  - test
  - build
  - deploy

test:
  script:
    - flutter test --coverage
    - flutter analyze
    - dart format --set-exit-if-changed .

build:
  script:
    - flutter build apk --release --dart-define-from-file=env/production.json
    - flutter build appbundle --release --dart-define-from-file=env/production.json

deploy:
  script:
    - fastlane deploy
    - notify_team "Deployment successful"
```

### 10.2 Monitoring & Analytics
```dart
class AnalyticsService {
  static Future<void> trackUserAction(String action, Map<String, dynamic> properties) async {
    await supabase.from('user_actions').insert({
      'user_id': supabase.auth.currentUser?.id,
      'action': action,
      'properties': properties,
      'timestamp': DateTime.now().toIso8601String(),
      'device_info': await _getDeviceInfo(),
    });
  }
  
  static Future<void> trackError(String error, String stackTrace) async {
    await supabase.from('error_logs').insert({
      'user_id': supabase.auth.currentUser?.id,
      'error_message': error,
      'stack_trace': stackTrace,
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': await _getAppVersion(),
    });
  }
}
```

This comprehensive architecture blueprint provides a scalable, secure, and maintainable foundation for FurniShop Manager, supporting all PRD requirements while maintaining the existing Flutter/Supabase foundation. The design emphasizes offline-first capabilities, role-based security, and real-time synchronization suitable for 50+ concurrent users.