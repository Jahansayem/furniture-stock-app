# FurniShop Manager - Backend Integration Strategy

## Executive Summary

Comprehensive backend integration plan for FurniTrack furniture inventory management system, focusing on scalable architecture, security, and real-time capabilities.

**Current State**: Basic Supabase setup with auth, core tables, basic RLS policies, Steadfast courier integration, OneSignal notifications.

**Target State**: Production-ready backend with advanced RLS, real-time subscriptions, comprehensive integrations, and enterprise-grade security.

---

## 1. Enhanced Supabase Schema Design

### 1.1 Complete Database Schema Overview

```sql
-- =====================================================
-- ENHANCED FURNITURE STOCK MANAGEMENT SCHEMA
-- =====================================================

-- Core Business Entities
├── user_profiles (Enhanced with role management)
├── products (Enhanced with categories, variants, pricing)
├── stock_locations (Enhanced with hierarchical structure)
├── stocks (Enhanced with lot tracking, expiry dates)
├── stock_movements (Enhanced audit trail)
├── sales (Enhanced with payment tracking, customer management)
├── orders (NEW - Complete order management)
├── customers (NEW - Customer relationship management)
├── suppliers (NEW - Supply chain management)
├── purchase_orders (NEW - Procurement management)
├── production_jobs (NEW - Manufacturing tracking)
├── attendance_log (Enhanced with break tracking)
├── notifications (Enhanced with rich media)
├── audit_logs (NEW - Complete audit trail)
├── reports_cache (NEW - Performance optimization)
└── system_settings (NEW - Configuration management)
```

### 1.2 Extended Data Models

#### Enhanced Products Table
```sql
-- Enhanced products with comprehensive furniture management
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS product_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES product_categories(id),
ADD COLUMN IF NOT EXISTS brand TEXT,
ADD COLUMN IF NOT EXISTS dimensions JSONB, -- {width, height, depth, weight}
ADD COLUMN IF NOT EXISTS materials JSONB, -- ["wood", "metal", "fabric"]
ADD COLUMN IF NOT EXISTS colors JSONB, -- ["red", "blue", "natural"]
ADD COLUMN IF NOT EXISTS finish_type TEXT,
ADD COLUMN IF NOT EXISTS assembly_required BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS assembly_time_minutes INTEGER,
ADD COLUMN IF NOT EXISTS warranty_months INTEGER DEFAULT 12,
ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES suppliers(id),
ADD COLUMN IF NOT EXISTS cost_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS markup_percentage DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS tax_rate DECIMAL(5,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS tags TEXT[], -- For search and filtering
ADD COLUMN IF NOT EXISTS seo_keywords TEXT[],
ADD COLUMN IF NOT EXISTS care_instructions TEXT,
ADD COLUMN IF NOT EXISTS packaging_dimensions JSONB,
ADD COLUMN IF NOT EXISTS shipping_weight DECIMAL(8,2),
ADD COLUMN IF NOT EXISTS min_order_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS max_order_quantity INTEGER,
ADD COLUMN IF NOT EXISTS seasonal BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS featured BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS bestseller BOOLEAN DEFAULT false;

-- Create product categories table
CREATE TABLE IF NOT EXISTS product_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id UUID REFERENCES product_categories(id),
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    image_url TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create product variants table (colors, sizes, materials)
CREATE TABLE IF NOT EXISTS product_variants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    variant_name TEXT NOT NULL, -- "Red Leather", "Large Size"
    variant_type TEXT NOT NULL, -- "color", "size", "material"
    variant_value TEXT NOT NULL, -- "red", "large", "leather"
    price_adjustment DECIMAL(10,2) DEFAULT 0.00,
    cost_adjustment DECIMAL(10,2) DEFAULT 0.00,
    sku_suffix TEXT, -- Append to base SKU
    image_urls TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create product images table for gallery
CREATE TABLE IF NOT EXISTS product_images (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    alt_text TEXT,
    sort_order INTEGER DEFAULT 0,
    is_primary BOOLEAN DEFAULT false,
    file_size INTEGER, -- in bytes
    width INTEGER,
    height INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Enhanced Sales and Order Management
```sql
-- Enhanced sales table with complete order lifecycle
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES orders(id),
ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customers(id),
ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS discount_percentage DECIMAL(5,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS shipping_amount DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS net_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS payment_method TEXT, -- 'cash', 'card', 'bank_transfer', 'cod'
ADD COLUMN IF NOT EXISTS payment_reference TEXT,
ADD COLUMN IF NOT EXISTS payment_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS refund_amount DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS refund_reason TEXT,
ADD COLUMN IF NOT EXISTS warranty_start_date DATE,
ADD COLUMN IF NOT EXISTS warranty_end_date DATE,
ADD COLUMN IF NOT EXISTS installation_required BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS installation_date DATE,
ADD COLUMN IF NOT EXISTS installer_notes TEXT;

-- Create comprehensive orders table
CREATE TABLE IF NOT EXISTS orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_number TEXT UNIQUE NOT NULL, -- ORD-2024-001
    customer_id UUID REFERENCES customers(id),
    order_type TEXT NOT NULL CHECK (order_type IN ('sale', 'return', 'exchange', 'warranty')),
    order_status TEXT NOT NULL DEFAULT 'draft' CHECK (order_status IN (
        'draft', 'confirmed', 'processing', 'ready_for_delivery', 
        'in_transit', 'delivered', 'completed', 'cancelled', 'refunded'
    )),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    
    -- Pricing
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    tax_amount DECIMAL(10,2) DEFAULT 0.00,
    shipping_amount DECIMAL(10,2) DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    
    -- Delivery Information
    delivery_type TEXT CHECK (delivery_type IN ('pickup', 'home_delivery', 'white_glove')),
    delivery_address JSONB, -- Full address object
    delivery_date DATE,
    delivery_time_slot TEXT, -- "9AM-12PM", "2PM-5PM"
    delivery_instructions TEXT,
    
    -- Special Requirements
    assembly_required BOOLEAN DEFAULT false,
    installation_required BOOLEAN DEFAULT false,
    special_instructions TEXT,
    
    -- Tracking
    created_by UUID REFERENCES auth.users(id),
    assigned_to UUID REFERENCES auth.users(id), -- Sales person
    source TEXT DEFAULT 'store' CHECK (source IN ('store', 'online', 'phone', 'whatsapp')),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    confirmed_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- Create order items table for detailed line items
CREATE TABLE IF NOT EXISTS order_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    variant_id UUID REFERENCES product_variants(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    tax_rate DECIMAL(5,2) DEFAULT 0.00,
    tax_amount DECIMAL(10,2) DEFAULT 0.00,
    line_total DECIMAL(10,2) NOT NULL,
    
    -- Product snapshot at time of order
    product_name TEXT NOT NULL,
    product_code TEXT,
    variant_name TEXT,
    
    -- Fulfillment
    reserved_stock_id UUID, -- Link to stock reservation
    picked_quantity INTEGER DEFAULT 0,
    delivered_quantity INTEGER DEFAULT 0,
    
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create customers table for CRM
CREATE TABLE IF NOT EXISTS customers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_code TEXT UNIQUE NOT NULL, -- CUST-001
    customer_type TEXT DEFAULT 'individual' CHECK (customer_type IN ('individual', 'business')),
    
    -- Personal Information
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE,
    phone TEXT NOT NULL,
    alternate_phone TEXT,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female', 'other')),
    
    -- Business Information (for business customers)
    company_name TEXT,
    tax_number TEXT,
    business_license TEXT,
    
    -- Address Information
    addresses JSONB[], -- Multiple addresses support
    default_address_index INTEGER DEFAULT 0,
    
    -- Marketing
    marketing_consent BOOLEAN DEFAULT false,
    preferred_contact_method TEXT DEFAULT 'phone' CHECK (preferred_contact_method IN ('phone', 'email', 'whatsapp', 'sms')),
    
    -- Loyalty & Preferences
    loyalty_points INTEGER DEFAULT 0,
    customer_tier TEXT DEFAULT 'regular' CHECK (customer_tier IN ('regular', 'silver', 'gold', 'platinum')),
    preferred_delivery_time TEXT,
    notes TEXT,
    
    -- Financial
    credit_limit DECIMAL(10,2) DEFAULT 0.00,
    outstanding_balance DECIMAL(10,2) DEFAULT 0.00,
    
    -- Tracking
    created_by UUID REFERENCES auth.users(id),
    last_order_date TIMESTAMPTZ,
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0.00,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Supply Chain Management
```sql
-- Create suppliers table
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    supplier_code TEXT UNIQUE NOT NULL, -- SUP-001
    company_name TEXT NOT NULL,
    contact_person TEXT,
    email TEXT,
    phone TEXT,
    website TEXT,
    
    -- Address
    address JSONB,
    
    -- Business Details
    tax_number TEXT,
    business_license TEXT,
    payment_terms TEXT, -- "Net 30", "COD"
    currency TEXT DEFAULT 'BDT',
    
    -- Performance Metrics
    lead_time_days INTEGER,
    quality_rating DECIMAL(3,2), -- 4.5 out of 5
    delivery_rating DECIMAL(3,2),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_preferred BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create purchase orders table
CREATE TABLE IF NOT EXISTS purchase_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    po_number TEXT UNIQUE NOT NULL, -- PO-2024-001
    supplier_id UUID REFERENCES suppliers(id),
    
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
        'draft', 'sent', 'confirmed', 'partially_received', 
        'received', 'completed', 'cancelled'
    )),
    
    -- Pricing
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(12,2) DEFAULT 0.00,
    tax_amount DECIMAL(12,2) DEFAULT 0.00,
    shipping_amount DECIMAL(12,2) DEFAULT 0.00,
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    
    -- Delivery
    expected_delivery_date DATE,
    delivery_address JSONB,
    
    -- Terms
    payment_terms TEXT,
    notes TEXT,
    
    -- Tracking
    created_by UUID REFERENCES auth.users(id),
    approved_by UUID REFERENCES auth.users(id),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    sent_at TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ
);

-- Create purchase order items
CREATE TABLE IF NOT EXISTS purchase_order_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    purchase_order_id UUID REFERENCES purchase_orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    
    quantity_ordered INTEGER NOT NULL,
    quantity_received INTEGER DEFAULT 0,
    unit_cost DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL,
    
    -- Product details at time of order
    product_name TEXT NOT NULL,
    product_code TEXT,
    
    expected_delivery_date DATE,
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Production Management
```sql
-- Create production jobs table
CREATE TABLE IF NOT EXISTS production_jobs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    job_number TEXT UNIQUE NOT NULL, -- JOB-2024-001
    product_id UUID REFERENCES products(id),
    order_id UUID REFERENCES orders(id), -- If made-to-order
    
    status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN (
        'queued', 'in_progress', 'quality_check', 'completed', 
        'on_hold', 'cancelled'
    )),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    
    quantity_planned INTEGER NOT NULL,
    quantity_completed INTEGER DEFAULT 0,
    quantity_defective INTEGER DEFAULT 0,
    
    -- Scheduling
    planned_start_date DATE,
    planned_end_date DATE,
    actual_start_date DATE,
    actual_end_date DATE,
    
    -- Resources
    assigned_workers TEXT[], -- User IDs
    machine_required TEXT,
    materials_required JSONB,
    
    -- Costing
    estimated_cost DECIMAL(10,2),
    actual_cost DECIMAL(10,2),
    labor_hours DECIMAL(6,2),
    
    notes TEXT,
    quality_notes TEXT,
    
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create production steps for detailed tracking
CREATE TABLE IF NOT EXISTS production_steps (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    production_job_id UUID REFERENCES production_jobs(id) ON DELETE CASCADE,
    step_name TEXT NOT NULL,
    step_order INTEGER NOT NULL,
    
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped')),
    
    estimated_duration_minutes INTEGER,
    actual_duration_minutes INTEGER,
    
    assigned_to UUID REFERENCES auth.users(id),
    completed_by UUID REFERENCES auth.users(id),
    
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    
    notes TEXT,
    quality_check_passed BOOLEAN,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 2. Advanced Row Level Security (RLS) Implementation

### 2.1 Role-Based Access Control

```sql
-- =====================================================
-- ENHANCED ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Define user roles and permissions
CREATE TYPE user_role AS ENUM (
    'owner',           -- Full access
    'manager',         -- Management functions, reports
    'sales_staff',     -- Sales, customer management
    'stock_staff',     -- Inventory management
    'production_staff', -- Production tracking
    'packaging_expert', -- Order fulfillment
    'delivery_staff',  -- Delivery management
    'viewer'           -- Read-only access
);

-- Helper function to get user role
CREATE OR REPLACE FUNCTION get_user_role(user_id UUID)
RETURNS TEXT AS $$
BEGIN
    RETURN (
        SELECT role 
        FROM user_profiles 
        WHERE id = user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user has permission
CREATE OR REPLACE FUNCTION user_has_permission(
    user_id UUID, 
    required_permissions TEXT[]
)
RETURNS BOOLEAN AS $$
DECLARE
    user_role TEXT;
BEGIN
    user_role := get_user_role(user_id);
    
    -- Owner has all permissions
    IF user_role = 'owner' THEN
        RETURN TRUE;
    END IF;
    
    -- Check if user role is in required permissions
    RETURN user_role = ANY(required_permissions);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 2.2 Granular RLS Policies

```sql
-- Products: Read access for all authenticated users, write for authorized roles
DROP POLICY IF EXISTS "Product access policy" ON products;
CREATE POLICY "Product access policy" ON products
    FOR ALL USING (
        CASE 
            WHEN TG_OP = 'SELECT' THEN auth.uid() IS NOT NULL
            ELSE user_has_permission(auth.uid(), ARRAY['owner', 'manager', 'stock_staff'])
        END
    );

-- Orders: Sales staff can manage their orders, managers see all
DROP POLICY IF EXISTS "Order access policy" ON orders;
CREATE POLICY "Order access policy" ON orders
    FOR ALL USING (
        CASE 
            WHEN get_user_role(auth.uid()) IN ('owner', 'manager') THEN TRUE
            WHEN get_user_role(auth.uid()) = 'sales_staff' THEN 
                created_by = auth.uid() OR assigned_to = auth.uid()
            WHEN get_user_role(auth.uid()) IN ('packaging_expert', 'delivery_staff') THEN 
                order_status IN ('ready_for_delivery', 'in_transit')
            ELSE FALSE
        END
    );

-- Customers: Sales staff and managers can access
DROP POLICY IF EXISTS "Customer access policy" ON customers;
CREATE POLICY "Customer access policy" ON customers
    FOR ALL USING (
        user_has_permission(auth.uid(), ARRAY['owner', 'manager', 'sales_staff'])
    );

-- Purchase Orders: Stock staff and managers
DROP POLICY IF EXISTS "Purchase order access policy" ON purchase_orders;
CREATE POLICY "Purchase order access policy" ON purchase_orders
    FOR ALL USING (
        user_has_permission(auth.uid(), ARRAY['owner', 'manager', 'stock_staff'])
    );

-- Production Jobs: Production and management staff
DROP POLICY IF EXISTS "Production job access policy" ON production_jobs;
CREATE POLICY "Production job access policy" ON production_jobs
    FOR ALL USING (
        user_has_permission(auth.uid(), ARRAY['owner', 'manager', 'production_staff'])
        OR (get_user_role(auth.uid()) = 'production_staff' AND auth.uid() = ANY(assigned_workers::UUID[]))
    );

-- Audit logs: Managers and owners only
DROP POLICY IF EXISTS "Audit log access policy" ON audit_logs;
CREATE POLICY "Audit log access policy" ON audit_logs
    FOR SELECT USING (
        user_has_permission(auth.uid(), ARRAY['owner', 'manager'])
    );

-- Financial data protection
DROP POLICY IF EXISTS "Sales financial data policy" ON sales;
CREATE POLICY "Sales financial data policy" ON sales
    FOR SELECT USING (
        CASE 
            WHEN user_has_permission(auth.uid(), ARRAY['owner', 'manager']) THEN TRUE
            WHEN get_user_role(auth.uid()) = 'sales_staff' THEN sold_by = auth.uid()
            ELSE FALSE
        END
    );
```

---

## 3. Real-time Subscriptions Architecture

### 3.1 Realtime Channel Strategy

```sql
-- =====================================================
-- REAL-TIME SUBSCRIPTION SETUP
-- =====================================================

-- Enable realtime for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE products;
ALTER PUBLICATION supabase_realtime ADD TABLE stocks;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE sales;
ALTER PUBLICATION supabase_realtime ADD TABLE stock_movements;
ALTER PUBLICATION supabase_realtime ADD TABLE production_jobs;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE user_profiles;

-- Create functions for real-time triggers
CREATE OR REPLACE FUNCTION notify_stock_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify on low stock
    IF NEW.quantity <= (SELECT low_stock_threshold FROM products WHERE id = NEW.product_id) THEN
        INSERT INTO notifications (
            user_id, title, message, type, data
        ) 
        SELECT 
            up.id,
            'Low Stock Alert',
            'Product ' || p.product_name || ' is running low at ' || sl.location_name,
            'warning',
            jsonb_build_object(
                'product_id', NEW.product_id,
                'location_id', NEW.location_id,
                'current_quantity', NEW.quantity,
                'threshold', p.low_stock_threshold
            )
        FROM products p, stock_locations sl, user_profiles up
        WHERE p.id = NEW.product_id 
        AND sl.id = NEW.location_id
        AND up.role IN ('owner', 'manager', 'stock_staff');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for stock changes
DROP TRIGGER IF EXISTS stock_change_notification ON stocks;
CREATE TRIGGER stock_change_notification
    AFTER UPDATE ON stocks
    FOR EACH ROW
    WHEN (OLD.quantity IS DISTINCT FROM NEW.quantity)
    EXECUTE FUNCTION notify_stock_change();
```

### 3.2 Client-side Subscription Management

```dart
// lib/services/realtime_service.dart
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, List<Function(Map<String, dynamic>)>> _listeners = {};

  /// Subscribe to stock changes for dashboard
  void subscribeToStockUpdates(Function(Map<String, dynamic>) callback) {
    final channel = _supabase
        .channel('stock_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stocks',
          callback: (payload) => callback(payload.newRecord ?? payload.oldRecord ?? {}),
        )
        .subscribe();
    
    _channels['stock_updates'] = channel;
    _addListener('stock_updates', callback);
  }

  /// Subscribe to order status changes
  void subscribeToOrderUpdates(String? orderId, Function(Map<String, dynamic>) callback) {
    final channelKey = 'order_updates_${orderId ?? 'all'}';
    
    final channel = _supabase
        .channel(channelKey)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: orderId != null ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ) : null,
          callback: (payload) => callback(payload.newRecord ?? {}),
        )
        .subscribe();
    
    _channels[channelKey] = channel;
    _addListener(channelKey, callback);
  }

  /// Subscribe to notifications for current user
  void subscribeToUserNotifications(Function(Map<String, dynamic>) callback) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final channel = _supabase
        .channel('user_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => callback(payload.newRecord ?? {}),
        )
        .subscribe();
    
    _channels['user_notifications'] = channel;
    _addListener('user_notifications', callback);
  }

  /// Subscribe to production job updates
  void subscribeToProductionUpdates(Function(Map<String, dynamic>) callback) {
    final channel = _supabase
        .channel('production_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'production_jobs',
          callback: (payload) => callback(payload.newRecord ?? payload.oldRecord ?? {}),
        )
        .subscribe();
    
    _channels['production_updates'] = channel;
    _addListener('production_updates', callback);
  }

  /// Presence tracking for team collaboration
  void joinPresenceChannel(String channelName, Map<String, dynamic> userInfo) {
    final channel = _supabase
        .channel(channelName)
        .onPresenceSync((syncs) {
          // Handle presence sync
          AppLogger.info('Presence sync: ${syncs.length} users online');
        })
        .onPresenceJoin((joins) {
          AppLogger.info('User joined: $joins');
        })
        .onPresenceLeave((leaves) {
          AppLogger.info('User left: $leaves');
        })
        .subscribe();
    
    // Track current user presence
    channel.track(userInfo);
    _channels[channelName] = channel;
  }

  void _addListener(String channelKey, Function(Map<String, dynamic>) callback) {
    _listeners[channelKey] ??= [];
    _listeners[channelKey]!.add(callback);
  }

  void unsubscribeAll() {
    for (final channel in _channels.values) {
      _supabase.removeChannel(channel);
    }
    _channels.clear();
    _listeners.clear();
  }

  void unsubscribe(String channelKey) {
    final channel = _channels[channelKey];
    if (channel != null) {
      _supabase.removeChannel(channel);
      _channels.remove(channelKey);
      _listeners.remove(channelKey);
    }
  }
}
```

---

## 4. Steadfast Courier API Enhanced Integration

### 4.1 Advanced Courier Management

```dart
// lib/services/enhanced_courier_service.dart
class EnhancedCourierService {
  static final EnhancedCourierService _instance = EnhancedCourierService._internal();
  factory EnhancedCourierService() => _instance;
  EnhancedCourierService._internal();

  final SteadFastService _steadfast = SteadFastService();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create courier order with comprehensive tracking
  Future<CourierOrderResult> createCourierOrder({
    required String orderId,
    required CourierOrderRequest request,
  }) async {
    try {
      // Create Steadfast order
      final steadfastResponse = await _steadfast.createOrder(
        invoice: request.invoiceNumber,
        recipientName: request.recipientName,
        recipientPhone: request.recipientPhone,
        recipientAddress: request.recipientAddress,
        codAmount: request.codAmount,
        notes: request.notes,
      );

      if (steadfastResponse?.success == true) {
        // Update order with courier information
        await _supabase.from('orders').update({
          'courier_service': 'steadfast',
          'consignment_id': steadfastResponse!.consignmentId,
          'tracking_code': steadfastResponse.trackingCode,
          'courier_status': 'order_placed',
          'courier_created_at': DateTime.now().toIso8601String(),
          'order_status': 'in_transit',
        }).eq('id', orderId);

        // Create courier tracking record
        await _createCourierTracking(
          orderId: orderId,
          consignmentId: steadfastResponse.consignmentId!,
          trackingCode: steadfastResponse.trackingCode,
        );

        // Send notifications
        await _notifyStakeholders(
          orderId: orderId,
          eventType: 'courier_order_created',
          data: {
            'consignment_id': steadfastResponse.consignmentId,
            'tracking_code': steadfastResponse.trackingCode,
          },
        );

        return CourierOrderResult.success(
          consignmentId: steadfastResponse.consignmentId!,
          trackingCode: steadfastResponse.trackingCode,
        );
      } else {
        return CourierOrderResult.failure(
          error: steadfastResponse?.message ?? 'Failed to create courier order',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to create courier order', error: e);
      return CourierOrderResult.failure(error: e.toString());
    }
  }

  /// Batch tracking update for all active shipments
  Future<void> updateAllShipmentStatuses() async {
    try {
      // Get all active shipments
      final activeShipments = await _supabase
          .from('orders')
          .select('id, consignment_id, tracking_code')
          .not('consignment_id', 'is', null)
          .not('courier_status', 'in', ['delivered', 'returned', 'cancelled'])
          .limit(50); // Process in batches

      final futures = <Future>[];

      for (final shipment in activeShipments) {
        futures.add(_updateSingleShipmentStatus(
          orderId: shipment['id'],
          consignmentId: shipment['consignment_id'],
          trackingCode: shipment['tracking_code'],
        ));
      }

      await Future.wait(futures);
      AppLogger.info('Updated status for ${activeShipments.length} shipments');
    } catch (e) {
      AppLogger.error('Failed to update shipment statuses', error: e);
    }
  }

  Future<void> _updateSingleShipmentStatus({
    required String orderId,
    required String consignmentId,
    String? trackingCode,
  }) async {
    try {
      final statusResponse = await _steadfast.checkStatus(
        consignmentId: consignmentId,
        trackingCode: trackingCode,
      );

      if (statusResponse?.success == true && statusResponse?.status != null) {
        // Update order status
        final orderStatus = _mapCourierStatusToOrderStatus(statusResponse!.status!);
        
        await _supabase.from('orders').update({
          'courier_status': statusResponse.status,
          'order_status': orderStatus,
          'delivery_date': statusResponse.deliveryDate,
          'courier_notes': statusResponse.note,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);

        // Add tracking event
        await _addTrackingEvent(
          orderId: orderId,
          status: statusResponse.status!,
          description: statusResponse.note,
          timestamp: DateTime.now(),
        );

        // Notify on status change
        if (_shouldNotifyOnStatus(statusResponse.status!)) {
          await _notifyStakeholders(
            orderId: orderId,
            eventType: 'delivery_status_updated',
            data: {
              'status': statusResponse.status,
              'delivery_date': statusResponse.deliveryDate,
            },
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to update shipment $consignmentId', error: e);
    }
  }

  String _mapCourierStatusToOrderStatus(String courierStatus) {
    switch (courierStatus.toLowerCase()) {
      case 'pending':
      case 'in_review':
        return 'processing';
      case 'picked_up':
      case 'in_transit':
        return 'in_transit';
      case 'delivered':
        return 'delivered';
      case 'returned':
      case 'cancelled':
        return 'cancelled';
      default:
        return 'in_transit';
    }
  }

  bool _shouldNotifyOnStatus(String status) {
    return ['delivered', 'returned', 'cancelled', 'out_for_delivery'].contains(status.toLowerCase());
  }

  Future<void> _createCourierTracking({
    required String orderId,
    required String consignmentId,
    String? trackingCode,
  }) async {
    await _supabase.from('courier_tracking').insert({
      'id': Uuid().v4(),
      'order_id': orderId,
      'consignment_id': consignmentId,
      'tracking_code': trackingCode,
      'courier_service': 'steadfast',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _addTrackingEvent({
    required String orderId,
    required String status,
    String? description,
    required DateTime timestamp,
  }) async {
    await _supabase.from('courier_tracking_events').insert({
      'id': Uuid().v4(),
      'order_id': orderId,
      'status': status,
      'description': description,
      'event_timestamp': timestamp.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _notifyStakeholders({
    required String orderId,
    required String eventType,
    required Map<String, dynamic> data,
  }) async {
    // Get order details for notification
    final order = await _supabase
        .from('orders')
        .select('order_number, customer_id, created_by, assigned_to')
        .eq('id', orderId)
        .single();

    final notifications = <Map<String, dynamic>>[];

    // Notify customer if they have an account
    if (order['customer_id'] != null) {
      notifications.add({
        'user_id': order['customer_id'],
        'title': _getNotificationTitle(eventType),
        'message': _getNotificationMessage(eventType, order['order_number'], data),
        'type': 'info',
        'data': jsonEncode({...data, 'order_id': orderId}),
      });
    }

    // Notify sales staff
    if (order['created_by'] != null) {
      notifications.add({
        'user_id': order['created_by'],
        'title': _getNotificationTitle(eventType),
        'message': _getNotificationMessage(eventType, order['order_number'], data),
        'type': 'info',
        'data': jsonEncode({...data, 'order_id': orderId}),
      });
    }

    if (notifications.isNotEmpty) {
      await _supabase.from('notifications').insert(notifications);
    }
  }

  String _getNotificationTitle(String eventType) {
    switch (eventType) {
      case 'courier_order_created':
        return 'Order Shipped';
      case 'delivery_status_updated':
        return 'Delivery Update';
      default:
        return 'Order Update';
    }
  }

  String _getNotificationMessage(String eventType, String orderNumber, Map<String, dynamic> data) {
    switch (eventType) {
      case 'courier_order_created':
        return 'Order $orderNumber has been shipped. Tracking: ${data['tracking_code']}';
      case 'delivery_status_updated':
        return 'Order $orderNumber status updated to: ${data['status']}';
      default:
        return 'Order $orderNumber has been updated';
    }
  }
}

// Supporting models
class CourierOrderRequest {
  final String invoiceNumber;
  final String recipientName;
  final String recipientPhone;
  final String recipientAddress;
  final double codAmount;
  final String? notes;

  CourierOrderRequest({
    required this.invoiceNumber,
    required this.recipientName,
    required this.recipientPhone,
    required this.recipientAddress,
    required this.codAmount,
    this.notes,
  });
}

class CourierOrderResult {
  final bool success;
  final String? consignmentId;
  final String? trackingCode;
  final String? error;

  CourierOrderResult._({
    required this.success,
    this.consignmentId,
    this.trackingCode,
    this.error,
  });

  factory CourierOrderResult.success({
    required String consignmentId,
    String? trackingCode,
  }) =>
      CourierOrderResult._(
        success: true,
        consignmentId: consignmentId,
        trackingCode: trackingCode,
      );

  factory CourierOrderResult.failure({required String error}) =>
      CourierOrderResult._(success: false, error: error);
}
```

### 4.2 Courier Tracking Tables

```sql
-- Create comprehensive courier tracking tables
CREATE TABLE IF NOT EXISTS courier_tracking (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    consignment_id TEXT NOT NULL,
    tracking_code TEXT,
    courier_service TEXT NOT NULL, -- 'steadfast', 'pathao', 'redx'
    
    -- Shipping details
    pickup_date DATE,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    
    -- Current status
    current_status TEXT,
    last_status_update TIMESTAMPTZ,
    
    -- Delivery attempt tracking
    delivery_attempts INTEGER DEFAULT 0,
    failed_delivery_reasons TEXT[],
    
    -- Financial
    cod_amount DECIMAL(10,2),
    delivery_charge DECIMAL(8,2),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS courier_tracking_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    courier_tracking_id UUID REFERENCES courier_tracking(id) ON DELETE CASCADE,
    
    status TEXT NOT NULL,
    description TEXT,
    location TEXT,
    
    event_timestamp TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_courier_tracking_order_id ON courier_tracking(order_id);
CREATE INDEX IF NOT EXISTS idx_courier_tracking_consignment_id ON courier_tracking(consignment_id);
CREATE INDEX IF NOT EXISTS idx_courier_tracking_events_order_id ON courier_tracking_events(order_id);
CREATE INDEX IF NOT EXISTS idx_courier_tracking_events_timestamp ON courier_tracking_events(event_timestamp DESC);
```

---

## 5. OneSignal Enhanced Integration

### 5.1 Rich Notification System

```dart
// lib/services/enhanced_notification_service.dart
class EnhancedNotificationService {
  static final EnhancedNotificationService _instance = EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send rich notification with product images
  Future<void> sendProductNotification({
    required List<String> userIds,
    required String title,
    required String message,
    required String productId,
    String? imageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get product details
      final product = await _supabase
          .from('products')
          .select('product_name, image_url, price')
          .eq('id', productId)
          .single();

      final notificationData = {
        'type': 'product',
        'product_id': productId,
        'product_name': product['product_name'],
        'product_price': product['price'],
        'action_url': '/products/$productId',
        ...?additionalData,
      };

      // Send OneSignal notification with rich content
      await _sendOneSignalNotification(
        userIds: userIds,
        title: title,
        message: message,
        imageUrl: imageUrl ?? product['image_url'],
        data: notificationData,
        buttons: [
          {
            'id': 'view_product',
            'text': 'View Product',
            'icon': 'ic_visibility',
          },
          {
            'id': 'add_to_cart',
            'text': 'Add to Order',
            'icon': 'ic_add_shopping_cart',
          },
        ],
      );

      // Save notification to database
      await _saveNotificationsToDb(
        userIds: userIds,
        title: title,
        message: message,
        type: 'product',
        data: notificationData,
      );
    } catch (e) {
      AppLogger.error('Failed to send product notification', error: e);
    }
  }

  /// Send order status notification
  Future<void> sendOrderStatusNotification({
    required String orderId,
    required String newStatus,
    String? customerMessage,
  }) async {
    try {
      // Get order details
      final order = await _supabase
          .from('orders')
          .select('''
            id, order_number, total_amount, customer_id, created_by, assigned_to,
            customers(first_name, last_name, phone),
            order_items(product_name, quantity)
          ''')
          .eq('id', orderId)
          .single();

      final orderNumber = order['order_number'];
      final customerName = '${order['customers']['first_name']} ${order['customers']['last_name']}';
      
      // Determine notification recipients and messages
      final notifications = <NotificationTarget>[];

      // Customer notification
      if (order['customer_id'] != null) {
        notifications.add(NotificationTarget(
          userId: order['customer_id'],
          title: 'Order Update - $orderNumber',
          message: customerMessage ?? _getCustomerStatusMessage(newStatus, orderNumber),
        ));
      }

      // Staff notifications
      final staffUserIds = [order['created_by'], order['assigned_to']]
          .where((id) => id != null)
          .cast<String>()
          .toList();

      for (final userId in staffUserIds) {
        notifications.add(NotificationTarget(
          userId: userId,
          title: 'Order Status Changed',
          message: 'Order $orderNumber for $customerName is now $newStatus',
        ));
      }

      // Send notifications
      for (final notification in notifications) {
        await _sendOneSignalNotification(
          userIds: [notification.userId],
          title: notification.title,
          message: notification.message,
          data: {
            'type': 'order_status',
            'order_id': orderId,
            'order_number': orderNumber,
            'status': newStatus,
            'action_url': '/orders/$orderId',
          },
          buttons: [
            {
              'id': 'view_order',
              'text': 'View Order',
              'icon': 'ic_receipt',
            },
          ],
        );
      }

      // Save to database
      await _saveNotificationsToDb(
        userIds: notifications.map((n) => n.userId).toList(),
        title: 'Order Status Update',
        message: 'Order $orderNumber status changed to $newStatus',
        type: 'order_status',
        data: {
          'order_id': orderId,
          'order_number': orderNumber,
          'status': newStatus,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to send order status notification', error: e);
    }
  }

  /// Send low stock alert with product image
  Future<void> sendLowStockAlert({
    required String productId,
    required String locationId,
    required int currentStock,
    required int threshold,
  }) async {
    try {
      // Get product and location details
      final data = await _supabase
          .from('stocks')
          .select('''
            products(product_name, image_url, price),
            stock_locations(location_name)
          ''')
          .eq('product_id', productId)
          .eq('location_id', locationId)
          .single();

      final productName = data['products']['product_name'];
      final locationName = data['stock_locations']['location_name'];
      final imageUrl = data['products']['image_url'];

      // Get users who should receive stock alerts
      final alertUsers = await _supabase
          .from('user_profiles')
          .select('id')
          .in_('role', ['owner', 'manager', 'stock_staff']);

      final userIds = alertUsers.map((u) => u['id'] as String).toList();

      await _sendOneSignalNotification(
        userIds: userIds,
        title: '🚨 Low Stock Alert',
        message: '$productName at $locationName: $currentStock remaining (threshold: $threshold)',
        imageUrl: imageUrl,
        data: {
          'type': 'low_stock',
          'product_id': productId,
          'location_id': locationId,
          'current_stock': currentStock,
          'threshold': threshold,
          'action_url': '/inventory/products/$productId',
        },
        buttons: [
          {
            'id': 'restock',
            'text': 'Create Restock Order',
            'icon': 'ic_add_box',
          },
          {
            'id': 'view_stock',
            'text': 'View Stock',
            'icon': 'ic_inventory',
          },
        ],
      );

      await _saveNotificationsToDb(
        userIds: userIds,
        title: 'Low Stock Alert',
        message: '$productName at $locationName is running low',
        type: 'low_stock',
        data: {
          'product_id': productId,
          'location_id': locationId,
          'current_stock': currentStock,
          'threshold': threshold,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to send low stock alert', error: e);
    }
  }

  /// Send promotional notification with product showcase
  Future<void> sendPromotionalNotification({
    required String title,
    required String message,
    List<String>? targetUserIds,
    List<String>? productIds,
    String? promoCode,
    String? imageUrl,
  }) async {
    try {
      // If no target users specified, send to all active customers
      List<String> userIds = targetUserIds ?? [];
      if (userIds.isEmpty) {
        final customers = await _supabase
            .from('user_profiles')
            .select('id')
            .eq('role', 'customer')
            .eq('is_active', true);
        userIds = customers.map((c) => c['id'] as String).toList();
      }

      final notificationData = {
        'type': 'promotion',
        'promo_code': promoCode,
        'product_ids': productIds,
        'action_url': '/promotions${promoCode != null ? '?code=$promoCode' : ''}',
      };

      await _sendOneSignalNotification(
        userIds: userIds,
        title: title,
        message: message,
        imageUrl: imageUrl,
        data: notificationData,
        buttons: [
          {
            'id': 'view_promotion',
            'text': 'View Offer',
            'icon': 'ic_local_offer',
          },
          if (promoCode != null) {
            'id': 'copy_code',
            'text': 'Copy Code',
            'icon': 'ic_content_copy',
          },
        ],
      );

      await _saveNotificationsToDb(
        userIds: userIds,
        title: title,
        message: message,
        type: 'promotion',
        data: notificationData,
      );
    } catch (e) {
      AppLogger.error('Failed to send promotional notification', error: e);
    }
  }

  Future<void> _sendOneSignalNotification({
    required List<String> userIds,
    required String title,
    required String message,
    String? imageUrl,
    Map<String, dynamic>? data,
    List<Map<String, String>>? buttons,
  }) async {
    try {
      // Get OneSignal player IDs for users
      final users = await _supabase
          .from('user_profiles')
          .select('onesignal_player_id')
          .in_('id', userIds)
          .not('onesignal_player_id', 'is', null);

      final playerIds = users
          .map((u) => u['onesignal_player_id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();

      if (playerIds.isEmpty) {
        AppLogger.warning('No OneSignal player IDs found for notification');
        return;
      }

      // Prepare OneSignal notification
      final notification = {
        'app_id': OneSignalConfig.appId,
        'include_player_ids': playerIds,
        'headings': {'en': title},
        'contents': {'en': message},
        'data': data ?? {},
      };

      // Add image if provided
      if (imageUrl != null && imageUrl.isNotEmpty) {
        notification['big_picture'] = imageUrl;
        notification['ios_attachments'] = {'id1': imageUrl};
      }

      // Add action buttons if provided
      if (buttons != null && buttons.isNotEmpty) {
        notification['buttons'] = buttons;
      }

      // Send via OneSignal REST API
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${OneSignalConfig.restApiKey}',
        },
        body: jsonEncode(notification),
      );

      if (response.statusCode == 200) {
        AppLogger.info('OneSignal notification sent successfully');
      } else {
        AppLogger.error('OneSignal API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.error('Failed to send OneSignal notification', error: e);
    }
  }

  Future<void> _saveNotificationsToDb({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final notifications = userIds.map((userId) => {
      'id': Uuid().v4(),
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'data': jsonEncode(data),
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    }).toList();

    await _supabase.from('notifications').insert(notifications);
  }

  String _getCustomerStatusMessage(String status, String orderNumber) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Your order $orderNumber has been confirmed and is being prepared.';
      case 'processing':
        return 'Your order $orderNumber is being processed.';
      case 'ready_for_delivery':
        return 'Your order $orderNumber is ready for delivery!';
      case 'in_transit':
        return 'Your order $orderNumber is on the way to you.';
      case 'delivered':
        return 'Your order $orderNumber has been delivered. Thank you!';
      case 'cancelled':
        return 'Your order $orderNumber has been cancelled. We apologize for any inconvenience.';
      default:
        return 'Your order $orderNumber status has been updated to $status.';
    }
  }
}

class NotificationTarget {
  final String userId;
  final String title;
  final String message;

  NotificationTarget({
    required this.userId,
    required this.title,
    required this.message,
  });
}
```

---

## 6. PDF Generation Strategy

### 6.1 Server-side PDF Generation (Recommended)

```sql
-- Create Supabase Edge Function for PDF generation
-- supabase/functions/generate-pdf/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { jsPDF } from 'https://esm.sh/jspdf@2.5.1'
import 'https://esm.sh/jspdf-autotable@3.5.25'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    const { reportType, orderId, dateRange, filters } = await req.json()

    let pdfBuffer: Uint8Array

    switch (reportType) {
      case 'invoice':
        pdfBuffer = await generateInvoice(supabase, orderId)
        break
      case 'sales_report':
        pdfBuffer = await generateSalesReport(supabase, dateRange, filters)
        break
      case 'stock_report':
        pdfBuffer = await generateStockReport(supabase, filters)
        break
      case 'production_report':
        pdfBuffer = await generateProductionReport(supabase, dateRange, filters)
        break
      default:
        throw new Error('Invalid report type')
    }

    return new Response(pdfBuffer, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="${reportType}_${new Date().toISOString().split('T')[0]}.pdf"`,
      },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

async function generateInvoice(supabase: any, orderId: string): Promise<Uint8Array> {
  // Fetch order data
  const { data: order } = await supabase
    .from('orders')
    .select(`
      *, 
      customers(*),
      order_items(*, products(*))
    `)
    .eq('id', orderId)
    .single()

  const doc = new jsPDF()
  
  // Company header
  doc.setFontSize(20)
  doc.text('FurniTrack Invoice', 105, 20, { align: 'center' })
  
  // Order details
  doc.setFontSize(12)
  doc.text(`Invoice: ${order.order_number}`, 20, 40)
  doc.text(`Date: ${new Date(order.created_at).toLocaleDateString()}`, 20, 50)
  doc.text(`Status: ${order.order_status}`, 20, 60)
  
  // Customer details
  doc.text('Bill To:', 20, 80)
  doc.text(`${order.customers.first_name} ${order.customers.last_name}`, 20, 90)
  doc.text(order.customers.phone, 20, 100)
  doc.text(order.customers.email || '', 20, 110)
  
  // Order items table
  const tableData = order.order_items.map((item: any) => [
    item.products.product_name,
    item.quantity.toString(),
    `$${item.unit_price.toFixed(2)}`,
    `$${item.line_total.toFixed(2)}`
  ])
  
  doc.autoTable({
    head: [['Product', 'Quantity', 'Unit Price', 'Total']],
    body: tableData,
    startY: 130,
  })
  
  // Totals
  const finalY = doc.lastAutoTable.finalY || 130
  doc.text(`Subtotal: $${order.subtotal.toFixed(2)}`, 140, finalY + 20)
  doc.text(`Tax: $${order.tax_amount.toFixed(2)}`, 140, finalY + 30)
  doc.text(`Total: $${order.total_amount.toFixed(2)}`, 140, finalY + 40)
  
  return new Uint8Array(doc.output('arraybuffer'))
}

async function generateSalesReport(supabase: any, dateRange: any, filters: any): Promise<Uint8Array> {
  const { data: sales } = await supabase
    .from('sales')
    .select('*, products(product_name), user_profiles(full_name)')
    .gte('created_at', dateRange.startDate)
    .lte('created_at', dateRange.endDate)
    .order('created_at', { ascending: false })

  const doc = new jsPDF()
  
  doc.setFontSize(20)
  doc.text('Sales Report', 105, 20, { align: 'center' })
  
  doc.setFontSize(12)
  doc.text(`Period: ${dateRange.startDate} to ${dateRange.endDate}`, 20, 40)
  
  // Summary metrics
  const totalSales = sales.reduce((sum: number, sale: any) => sum + sale.total_amount, 0)
  const totalOrders = sales.length
  const avgOrderValue = totalSales / totalOrders || 0
  
  doc.text(`Total Sales: $${totalSales.toFixed(2)}`, 20, 60)
  doc.text(`Total Orders: ${totalOrders}`, 20, 70)
  doc.text(`Average Order Value: $${avgOrderValue.toFixed(2)}`, 20, 80)
  
  // Sales table
  const tableData = sales.map((sale: any) => [
    new Date(sale.created_at).toLocaleDateString(),
    sale.products.product_name,
    sale.quantity.toString(),
    `$${sale.unit_price.toFixed(2)}`,
    `$${sale.total_amount.toFixed(2)}`,
    sale.user_profiles.full_name || 'Unknown'
  ])
  
  doc.autoTable({
    head: [['Date', 'Product', 'Qty', 'Unit Price', 'Total', 'Sold By']],
    body: tableData,
    startY: 100,
    styles: { fontSize: 8 }
  })
  
  return new Uint8Array(doc.output('arraybuffer'))
}

// Additional report generation functions...
```

### 6.2 Client-side PDF Integration

```dart
// lib/services/pdf_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PDFService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Generate invoice PDF
  static Future<Uint8List> generateInvoicePDF({
    required String orderId,
    bool includeLogo = true,
  }) async {
    // Fetch order data
    final order = await _supabase
        .from('orders')
        .select('''
          *, 
          customers(*),
          order_items(*, products(*)),
          user_profiles(full_name)
        ''')
        .eq('id', orderId)
        .single();

    final pdf = pw.Document();
    
    // Load company logo if needed
    pw.ImageProvider? logo;
    if (includeLogo) {
      try {
        final logoData = await _loadAssetImage('assets/logo.png');
        logo = pw.MemoryImage(logoData);
      } catch (e) {
        AppLogger.warning('Could not load logo for PDF: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (logo != null) 
                    pw.Image(logo, width: 100, height: 60),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', 
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text('${order['order_number']}'),
                      pw.Text('Date: ${_formatDate(order['created_at'])}'),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Company and customer info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FurniTrack Ltd.', 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('123 Business Street'),
                        pw.Text('Dhaka, Bangladesh'),
                        pw.Text('Phone: +880-1234-567890'),
                        pw.Text('Email: info@furnitrack.com'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To:', 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('${order['customers']['first_name']} ${order['customers']['last_name']}'),
                        pw.Text(order['customers']['phone']),
                        if (order['customers']['email'] != null)
                          pw.Text(order['customers']['email']),
                        if (order['delivery_address'] != null) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Delivery Address:', 
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(_formatAddress(order['delivery_address'])),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Order items table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableCell('Product', isHeader: true),
                      _buildTableCell('Qty', isHeader: true),
                      _buildTableCell('Unit Price', isHeader: true),
                      _buildTableCell('Total', isHeader: true),
                    ],
                  ),
                  // Items
                  ...order['order_items'].map<pw.TableRow>((item) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(item['products']['product_name']),
                        _buildTableCell(item['quantity'].toString()),
                        _buildTableCell('\$${item['unit_price'].toStringAsFixed(2)}'),
                        _buildTableCell('\$${item['line_total'].toStringAsFixed(2)}'),
                      ],
                    );
                  }).toList(),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Totals
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.SizedBox(width: 120, child: pw.Text('Subtotal:')),
                        pw.Text('\$${order['subtotal'].toStringAsFixed(2)}'),
                      ],
                    ),
                    if (order['discount_amount'] > 0) pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.SizedBox(width: 120, child: pw.Text('Discount:')),
                        pw.Text('-\$${order['discount_amount'].toStringAsFixed(2)}'),
                      ],
                    ),
                    if (order['tax_amount'] > 0) pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.SizedBox(width: 120, child: pw.Text('Tax:')),
                        pw.Text('\$${order['tax_amount'].toStringAsFixed(2)}'),
                      ],
                    ),
                    if (order['shipping_amount'] > 0) pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.SizedBox(width: 120, child: pw.Text('Shipping:')),
                        pw.Text('\$${order['shipping_amount'].toStringAsFixed(2)}'),
                      ],
                    ),
                    pw.Divider(thickness: 1),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.SizedBox(width: 120, child: pw.Text('Total:', 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Text('\$${order['total_amount'].toStringAsFixed(2)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Thank you for your business!',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text('Terms & Conditions: Payment due within 30 days.',
                      style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate comprehensive stock report
  static Future<Uint8List> generateStockReport({
    String? locationId,
    bool includeLowStock = true,
    bool includeImages = false,
  }) async {
    // Fetch stock data
    var query = _supabase
        .from('stocks')
        .select('''
          *, 
          products(product_name, product_code, price, low_stock_threshold, image_url),
          stock_locations(location_name)
        ''');

    if (locationId != null) {
      query = query.eq('location_id', locationId);
    }

    final stocks = await query.order('quantity', ascending: true);

    final pdf = pw.Document();
    final lowStockItems = stocks.where((stock) => 
        stock['quantity'] <= stock['products']['low_stock_threshold']).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text('Stock Report - ${DateTime.now().toString().split(' ')[0]}',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            
            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              color: PdfColors.grey100,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [
                    pw.Text('Total Products', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(stocks.length.toString(), style: const pw.TextStyle(fontSize: 18)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Low Stock Items', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(lowStockItems.length.toString(), style: const pw.TextStyle(fontSize: 18)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Total Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('\$${_calculateTotalStockValue(stocks).toStringAsFixed(2)}', 
                      style: const pw.TextStyle(fontSize: 18)),
                  ]),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Stock table
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Product Code', 'Product Name', 'Location', 'Current Stock', 'Threshold', 'Unit Price', 'Stock Value', 'Status'],
              data: stocks.map((stock) {
                final isLowStock = stock['quantity'] <= stock['products']['low_stock_threshold'];
                return [
                  stock['products']['product_code'] ?? 'N/A',
                  stock['products']['product_name'],
                  stock['stock_locations']['location_name'],
                  stock['quantity'].toString(),
                  stock['products']['low_stock_threshold'].toString(),
                  '\$${stock['products']['price'].toStringAsFixed(2)}',
                  '\$${(stock['quantity'] * stock['products']['price']).toStringAsFixed(2)}',
                  isLowStock ? 'LOW STOCK' : 'OK',
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              border: pw.TableBorder.all(),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              rowDecoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Preview and print PDF
  static Future<void> previewPDF(Uint8List pdfData, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdfData,
      name: title,
    );
  }

  /// Save PDF to device
  static Future<void> savePDF(Uint8List pdfData, String filename) async {
    await Printing.sharePdf(
      bytes: pdfData,
      filename: filename,
    );
  }

  // Helper methods
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 10 : 9,
        ),
      ),
    );
  }

  static String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatAddress(dynamic addressJson) {
    if (addressJson is String) return addressJson;
    if (addressJson is Map) {
      return [
        addressJson['street'],
        addressJson['city'],
        addressJson['state'],
        addressJson['postal_code'],
        addressJson['country'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    }
    return 'Address not available';
  }

  static double _calculateTotalStockValue(List<dynamic> stocks) {
    return stocks.fold(0.0, (sum, stock) => 
        sum + (stock['quantity'] * stock['products']['price']));
  }

  static Future<Uint8List> _loadAssetImage(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }
}
```

---

## 7. Advanced File Storage Strategy

### 7.1 Supabase Storage Configuration

```sql
-- =====================================================
-- ENHANCED STORAGE CONFIGURATION
-- =====================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('product-images', 'product-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('product-documents', 'product-documents', false, 10485760, ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
  ('user-documents', 'user-documents', false, 10485760, ARRAY['application/pdf', 'image/jpeg', 'image/png']),
  ('reports', 'reports', false, 52428800, ARRAY['application/pdf', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']),
  ('backups', 'backups', false, 1073741824, ARRAY['application/sql', 'application/gzip', 'application/zip'])
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Enhanced storage policies with role-based access
DROP POLICY IF EXISTS "Product images are publicly viewable" ON storage.objects;
CREATE POLICY "Product images are publicly viewable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'product-images');

DROP POLICY IF EXISTS "Authenticated users can upload product images" ON storage.objects;
CREATE POLICY "Authenticated users can upload product images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images' AND
    auth.uid() IS NOT NULL AND
    user_has_permission(auth.uid(), ARRAY['owner', 'manager', 'stock_staff'])
  );

DROP POLICY IF EXISTS "Authorized users can update product images" ON storage.objects;
CREATE POLICY "Authorized users can update product images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'product-images' AND
    user_has_permission(auth.uid(), ARRAY['owner', 'manager', 'stock_staff'])
  );

DROP POLICY IF EXISTS "Authorized users can delete product images" ON storage.objects;
CREATE POLICY "Authorized users can delete product images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'product-images' AND
    user_has_permission(auth.uid(), ARRAY['owner', 'manager'])
  );

-- Document storage policies
DROP POLICY IF EXISTS "Users can access their documents" ON storage.objects;
CREATE POLICY "Users can access their documents"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'user-documents' AND (
      auth.uid()::text = (storage.foldername(name))[1] OR
      user_has_permission(auth.uid(), ARRAY['owner', 'manager'])
    )
  );

-- Reports access
DROP POLICY IF EXISTS "Managers can access reports" ON storage.objects;
CREATE POLICY "Managers can access reports"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'reports' AND
    user_has_permission(auth.uid(), ARRAY['owner', 'manager'])
  );
```

### 7.2 File Upload Service with Optimization

```dart
// lib/services/file_storage_service.dart
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

class FileStorageService {
  static final FileStorageService _instance = FileStorageService._internal();
  factory FileStorageService() => _instance;
  FileStorageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload product image with optimization
  Future<FileUploadResult> uploadProductImage({
    required String productId,
    required Uint8List imageData,
    required String fileName,
    bool optimize = true,
    ImageQuality quality = ImageQuality.high,
  }) async {
    try {
      Uint8List processedData = imageData;
      
      if (optimize) {
        processedData = await _optimizeImage(imageData, quality);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last.toLowerCase();
      final uniqueFileName = '${productId}_$timestamp.$extension';
      final filePath = 'products/$productId/$uniqueFileName';

      // Upload to Supabase Storage
      await _supabase.storage
          .from('product-images')
          .uploadBinary(filePath, processedData);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('product-images')
          .getPublicUrl(filePath);

      // Save image record to database
      await _supabase.from('product_images').insert({
        'id': Uuid().v4(),
        'product_id': productId,
        'image_url': publicUrl,
        'alt_text': fileName.split('.').first,
        'file_size': processedData.length,
        'sort_order': await _getNextSortOrder(productId),
      });

      return FileUploadResult.success(
        url: publicUrl,
        filePath: filePath,
        fileSize: processedData.length,
      );
    } catch (e) {
      AppLogger.error('Failed to upload product image', error: e);
      return FileUploadResult.failure(error: e.toString());
    }
  }

  /// Upload multiple images for a product
  Future<List<FileUploadResult>> uploadProductImages({
    required String productId,
    required List<FileData> files,
    bool optimize = true,
    ImageQuality quality = ImageQuality.high,
  }) async {
    final results = <FileUploadResult>[];
    
    for (final file in files) {
      final result = await uploadProductImage(
        productId: productId,
        imageData: file.data,
        fileName: file.name,
        optimize: optimize,
        quality: quality,
      );
      results.add(result);
      
      // Small delay between uploads to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return results;
  }

  /// Upload document with virus scanning (placeholder for future implementation)
  Future<FileUploadResult> uploadDocument({
    required String bucketName,
    required String folderPath,
    required Uint8List documentData,
    required String fileName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate file type
      if (!_isAllowedDocumentType(fileName, bucketName)) {
        return FileUploadResult.failure(
          error: 'File type not allowed for this bucket',
        );
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last.toLowerCase();
      final uniqueFileName = '${timestamp}_$fileName';
      final filePath = '$folderPath/$uniqueFileName';

      // Upload to Supabase Storage
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(filePath, documentData, 
            fileOptions: FileOptions(
              upsert: false,
              metadata: metadata,
            ),
          );

      final publicUrl = bucketName.contains('public') 
          ? _supabase.storage.from(bucketName).getPublicUrl(filePath)
          : null;

      return FileUploadResult.success(
        url: publicUrl,
        filePath: filePath,
        fileSize: documentData.length,
      );
    } catch (e) {
      AppLogger.error('Failed to upload document', error: e);
      return FileUploadResult.failure(error: e.toString());
    }
  }

  /// Download file with progress tracking
  Future<Uint8List?> downloadFile({
    required String bucketName,
    required String filePath,
    Function(double)? onProgress,
  }) async {
    try {
      final response = await _supabase.storage
          .from(bucketName)
          .download(filePath);

      return response;
    } catch (e) {
      AppLogger.error('Failed to download file', error: e);
      return null;
    }
  }

  /// Delete file and update database
  Future<bool> deleteFile({
    required String bucketName,
    required String filePath,
    String? imageId,
  }) async {
    try {
      // Delete from storage
      await _supabase.storage
          .from(bucketName)
          .remove([filePath]);

      // Delete database record if it's an image
      if (imageId != null && bucketName == 'product-images') {
        await _supabase.from('product_images')
            .delete()
            .eq('id', imageId);
      }

      return true;
    } catch (e) {
      AppLogger.error('Failed to delete file', error: e);
      return false;
    }
  }

  /// Optimize image for web and mobile
  Future<Uint8List> _optimizeImage(Uint8List data, ImageQuality quality) async {
    try {
      final image = img.decodeImage(data);
      if (image == null) return data;

      // Resize if too large
      img.Image resized = image;
      const maxWidth = 1200;
      const maxHeight = 1200;

      if (image.width > maxWidth || image.height > maxHeight) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.height > image.width ? maxHeight : null,
        );
      }

      // Compress based on quality setting
      int jpegQuality;
      switch (quality) {
        case ImageQuality.low:
          jpegQuality = 60;
          break;
        case ImageQuality.medium:
          jpegQuality = 80;
          break;
        case ImageQuality.high:
          jpegQuality = 90;
          break;
      }

      final optimized = img.encodeJpg(resized, quality: jpegQuality);
      return Uint8List.fromList(optimized);
    } catch (e) {
      AppLogger.error('Failed to optimize image', error: e);
      return data; // Return original if optimization fails
    }
  }

  /// Generate thumbnail for images
  Future<Uint8List?> generateThumbnail(Uint8List imageData, {int size = 200}) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) return null;

      final thumbnail = img.copyResize(
        image,
        width: size,
        height: size,
        interpolation: img.Interpolation.average,
      );

      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 85));
    } catch (e) {
      AppLogger.error('Failed to generate thumbnail', error: e);
      return null;
    }
  }

  /// Get storage usage statistics
  Future<StorageStats> getStorageStats() async {
    try {
      final buckets = ['product-images', 'product-documents', 'user-documents', 'reports'];
      final stats = <String, BucketStats>{};
      
      for (final bucket in buckets) {
        final files = await _supabase.storage.from(bucket).list();
        final totalSize = files.fold<int>(0, (sum, file) => sum + (file.metadata?['size'] as int? ?? 0));
        
        stats[bucket] = BucketStats(
          fileCount: files.length,
          totalSize: totalSize,
        );
      }
      
      return StorageStats(bucketStats: stats);
    } catch (e) {
      AppLogger.error('Failed to get storage stats', error: e);
      return StorageStats(bucketStats: {});
    }
  }

  bool _isAllowedDocumentType(String fileName, String bucketName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (bucketName) {
      case 'product-images':
        return ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
      case 'product-documents':
      case 'user-documents':
        return ['pdf', 'doc', 'docx'].contains(extension);
      case 'reports':
        return ['pdf', 'xlsx', 'csv'].contains(extension);
      default:
        return false;
    }
  }

  Future<int> _getNextSortOrder(String productId) async {
    final result = await _supabase
        .from('product_images')
        .select('sort_order')
        .eq('product_id', productId)
        .order('sort_order', ascending: false)
        .limit(1);
    
    if (result.isEmpty) return 0;
    return (result.first['sort_order'] as int) + 1;
  }
}

// Supporting classes
enum ImageQuality { low, medium, high }

class FileData {
  final String name;
  final Uint8List data;
  final String? mimeType;

  FileData({
    required this.name,
    required this.data,
    this.mimeType,
  });
}

class FileUploadResult {
  final bool success;
  final String? url;
  final String? filePath;
  final int? fileSize;
  final String? error;

  FileUploadResult._({
    required this.success,
    this.url,
    this.filePath,
    this.fileSize,
    this.error,
  });

  factory FileUploadResult.success({
    String? url,
    String? filePath,
    int? fileSize,
  }) =>
      FileUploadResult._(
        success: true,
        url: url,
        filePath: filePath,
        fileSize: fileSize,
      );

  factory FileUploadResult.failure({required String error}) =>
      FileUploadResult._(success: false, error: error);
}

class StorageStats {
  final Map<String, BucketStats> bucketStats;

  StorageStats({required this.bucketStats});

  int get totalFiles => bucketStats.values.fold(0, (sum, stats) => sum + stats.fileCount);
  int get totalSize => bucketStats.values.fold(0, (sum, stats) => sum + stats.totalSize);
}

class BucketStats {
  final int fileCount;
  final int totalSize;

  BucketStats({required this.fileCount, required this.totalSize});
}
```

---

## 8. Data Migration Strategy

### 8.1 Migration Scripts and Procedures

```sql
-- =====================================================
-- DATA MIGRATION PROCEDURES
-- =====================================================

-- Create migration log table
CREATE TABLE IF NOT EXISTS migration_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    migration_name TEXT NOT NULL,
    migration_type TEXT NOT NULL, -- 'schema', 'data', 'cleanup'
    status TEXT NOT NULL CHECK (status IN ('pending', 'running', 'completed', 'failed', 'rolled_back')),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    records_processed INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    rollback_script TEXT
);

-- Migration: Add missing columns to existing tables
INSERT INTO migration_log (migration_name, migration_type, status) 
VALUES ('add_enhanced_columns', 'schema', 'running');

-- Safely add columns to existing products table
DO $$ 
BEGIN
    -- Add product code with unique constraint
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'product_code') THEN
        ALTER TABLE products ADD COLUMN product_code TEXT;
        
        -- Generate product codes for existing products
        UPDATE products 
        SET product_code = 'PROD-' || LPAD(ROW_NUMBER() OVER (ORDER BY created_at)::TEXT, 4, '0')
        WHERE product_code IS NULL;
        
        -- Add unique constraint
        ALTER TABLE products ADD CONSTRAINT products_product_code_unique UNIQUE (product_code);
    END IF;
    
    -- Add category support
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'category_id') THEN
        ALTER TABLE products ADD COLUMN category_id UUID;
        -- Will be populated after categories are created
    END IF;
    
    -- Add dimensions and materials
    ALTER TABLE products 
    ADD COLUMN IF NOT EXISTS dimensions JSONB,
    ADD COLUMN IF NOT EXISTS materials JSONB,
    ADD COLUMN IF NOT EXISTS colors JSONB,
    ADD COLUMN IF NOT EXISTS assembly_required BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS warranty_months INTEGER DEFAULT 12,
    ADD COLUMN IF NOT EXISTS tags TEXT[],
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
    
    -- Update migration log
    UPDATE migration_log 
    SET status = 'completed', completed_at = NOW(), records_processed = (SELECT COUNT(*) FROM products)
    WHERE migration_name = 'add_enhanced_columns';
    
EXCEPTION
    WHEN OTHERS THEN
        UPDATE migration_log 
        SET status = 'failed', completed_at = NOW(), error_message = SQLERRM
        WHERE migration_name = 'add_enhanced_columns';
        RAISE;
END $$;

-- Migration: Enhanced sales table
INSERT INTO migration_log (migration_name, migration_type, status) 
VALUES ('enhance_sales_table', 'schema', 'running');

DO $$
BEGIN
    -- Add order management columns
    ALTER TABLE sales 
    ADD COLUMN IF NOT EXISTS customer_id UUID,
    ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(10,2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS payment_method TEXT,
    ADD COLUMN IF NOT EXISTS payment_reference TEXT,
    ADD COLUMN IF NOT EXISTS refund_amount DECIMAL(10,2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS warranty_start_date DATE,
    ADD COLUMN IF NOT EXISTS installation_required BOOLEAN DEFAULT false;
    
    -- Calculate warranty dates for existing sales
    UPDATE sales 
    SET warranty_start_date = created_at::DATE,
        warranty_end_date = (created_at + INTERVAL '12 months')::DATE
    WHERE warranty_start_date IS NULL;
    
    UPDATE migration_log 
    SET status = 'completed', completed_at = NOW(), records_processed = (SELECT COUNT(*) FROM sales)
    WHERE migration_name = 'enhance_sales_table';
    
EXCEPTION
    WHEN OTHERS THEN
        UPDATE migration_log 
        SET status = 'failed', completed_at = NOW(), error_message = SQLERRM
        WHERE migration_name = 'enhance_sales_table';
        RAISE;
END $$;

-- Migration: Create default categories
INSERT INTO migration_log (migration_name, migration_type, status) 
VALUES ('create_default_categories', 'data', 'running');

DO $$
DECLARE
    living_room_id UUID;
    bedroom_id UUID;
    dining_id UUID;
    office_id UUID;
    storage_id UUID;
BEGIN
    -- Create main categories
    INSERT INTO product_categories (id, name, slug, description, sort_order) VALUES
    (gen_random_uuid(), 'Living Room', 'living-room', 'Furniture for living spaces', 1),
    (gen_random_uuid(), 'Bedroom', 'bedroom', 'Bedroom furniture and accessories', 2),
    (gen_random_uuid(), 'Dining Room', 'dining-room', 'Dining tables, chairs, and storage', 3),
    (gen_random_uuid(), 'Office', 'office', 'Home and office furniture', 4),
    (gen_random_uuid(), 'Storage', 'storage', 'Storage solutions and organizers', 5)
    ON CONFLICT (slug) DO NOTHING;
    
    -- Get category IDs for subcategories
    SELECT id INTO living_room_id FROM product_categories WHERE slug = 'living-room';
    SELECT id INTO bedroom_id FROM product_categories WHERE slug = 'bedroom';
    SELECT id INTO dining_id FROM product_categories WHERE slug = 'dining-room';
    SELECT id INTO office_id FROM product_categories WHERE slug = 'office';
    SELECT id INTO storage_id FROM product_categories WHERE slug = 'storage';
    
    -- Create subcategories
    INSERT INTO product_categories (id, name, parent_id, slug, sort_order) VALUES
    -- Living Room subcategories
    (gen_random_uuid(), 'Sofas', living_room_id, 'sofas', 1),
    (gen_random_uuid(), 'Coffee Tables', living_room_id, 'coffee-tables', 2),
    (gen_random_uuid(), 'TV Stands', living_room_id, 'tv-stands', 3),
    (gen_random_uuid(), 'Armchairs', living_room_id, 'armchairs', 4),
    
    -- Bedroom subcategories
    (gen_random_uuid(), 'Beds', bedroom_id, 'beds', 1),
    (gen_random_uuid(), 'Mattresses', bedroom_id, 'mattresses', 2),
    (gen_random_uuid(), 'Wardrobes', bedroom_id, 'wardrobes', 3),
    (gen_random_uuid(), 'Dressers', bedroom_id, 'dressers', 4),
    
    -- Dining subcategories
    (gen_random_uuid(), 'Dining Tables', dining_id, 'dining-tables', 1),
    (gen_random_uuid(), 'Dining Chairs', dining_id, 'dining-chairs', 2),
    (gen_random_uuid(), 'Bar Stools', dining_id, 'bar-stools', 3),
    
    -- Office subcategories
    (gen_random_uuid(), 'Office Desks', office_id, 'office-desks', 1),
    (gen_random_uuid(), 'Office Chairs', office_id, 'office-chairs', 2),
    (gen_random_uuid(), 'Bookcases', office_id, 'bookcases', 3),
    
    -- Storage subcategories
    (gen_random_uuid(), 'Shelving Units', storage_id, 'shelving-units', 1),
    (gen_random_uuid(), 'Cabinets', storage_id, 'cabinets', 2),
    (gen_random_uuid(), 'Chests', storage_id, 'chests', 3)
    ON CONFLICT (slug) DO NOTHING;
    
    UPDATE migration_log 
    SET status = 'completed', completed_at = NOW(), records_processed = (SELECT COUNT(*) FROM product_categories)
    WHERE migration_name = 'create_default_categories';
    
EXCEPTION
    WHEN OTHERS THEN
        UPDATE migration_log 
        SET status = 'failed', completed_at = NOW(), error_message = SQLERRM
        WHERE migration_name = 'create_default_categories';
        RAISE;
END $$;

-- Migration: Categorize existing products
INSERT INTO migration_log (migration_name, migration_type, status) 
VALUES ('categorize_existing_products', 'data', 'running');

DO $$
DECLARE
    uncategorized_id UUID;
BEGIN
    -- Create "Uncategorized" category
    INSERT INTO product_categories (id, name, slug, description, sort_order) 
    VALUES (gen_random_uuid(), 'Uncategorized', 'uncategorized', 'Products not yet categorized', 999)
    ON CONFLICT (slug) DO NOTHING;
    
    SELECT id INTO uncategorized_id FROM product_categories WHERE slug = 'uncategorized';
    
    -- Basic categorization based on product names
    UPDATE products SET category_id = (SELECT id FROM product_categories WHERE slug = 'sofas')
    WHERE category_id IS NULL AND (
        LOWER(product_name) LIKE '%sofa%' OR 
        LOWER(product_name) LIKE '%couch%' OR
        LOWER(product_type) LIKE '%sofa%'
    );
    
    UPDATE products SET category_id = (SELECT id FROM product_categories WHERE slug = 'beds')
    WHERE category_id IS NULL AND (
        LOWER(product_name) LIKE '%bed%' OR 
        LOWER(product_type) LIKE '%bed%'
    );
    
    UPDATE products SET category_id = (SELECT id FROM product_categories WHERE slug = 'dining-tables')
    WHERE category_id IS NULL AND (
        LOWER(product_name) LIKE '%table%' AND LOWER(product_name) LIKE '%dining%'
    );
    
    UPDATE products SET category_id = (SELECT id FROM product_categories WHERE slug = 'dining-chairs')
    WHERE category_id IS NULL AND (
        LOWER(product_name) LIKE '%chair%' AND LOWER(product_name) LIKE '%dining%'
    );
    
    UPDATE products SET category_id = (SELECT id FROM product_categories WHERE slug = 'office-chairs')
    WHERE category_id IS NULL AND (
        LOWER(product_name) LIKE '%chair%' AND (
            LOWER(product_name) LIKE '%office%' OR 
            LOWER(product_name) LIKE '%desk%'
        )
    );
    
    -- Put remaining products in uncategorized
    UPDATE products SET category_id = uncategorized_id WHERE category_id IS NULL;
    
    UPDATE migration_log 
    SET status = 'completed', completed_at = NOW(), 
        records_processed = (SELECT COUNT(*) FROM products WHERE category_id IS NOT NULL)
    WHERE migration_name = 'categorize_existing_products';
    
EXCEPTION
    WHEN OTHERS THEN
        UPDATE migration_log 
        SET status = 'failed', completed_at = NOW(), error_message = SQLERRM
        WHERE migration_name = 'categorize_existing_products';
        RAISE;
END $$;
```

### 8.2 Flutter Migration Service

```dart
// lib/services/migration_service.dart
class MigrationService {
  static final MigrationService _instance = MigrationService._internal();
  factory MigrationService() => _instance;
  MigrationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Run all pending migrations
  Future<MigrationResult> runMigrations() async {
    try {
      AppLogger.info('Starting database migration check...');
      
      // Check current schema version
      final currentVersion = await _getCurrentSchemaVersion();
      final targetVersion = await _getTargetSchemaVersion();
      
      if (currentVersion >= targetVersion) {
        AppLogger.info('Database is up to date (v$currentVersion)');
        return MigrationResult.success('Database is up to date');
      }
      
      AppLogger.info('Migrating database from v$currentVersion to v$targetVersion');
      
      // Run migrations in sequence
      final migrations = await _getPendingMigrations(currentVersion, targetVersion);
      int successCount = 0;
      
      for (final migration in migrations) {
        AppLogger.info('Running migration: ${migration.name}');
        
        try {
          await _runSingleMigration(migration);
          successCount++;
          AppLogger.info('✅ Migration ${migration.name} completed successfully');
        } catch (e) {
          AppLogger.error('❌ Migration ${migration.name} failed', error: e);
          return MigrationResult.failure(
            'Migration ${migration.name} failed: ${e.toString()}',
            successCount: successCount,
          );
        }
      }
      
      // Update schema version
      await _updateSchemaVersion(targetVersion);
      
      AppLogger.info('✅ All migrations completed successfully');
      return MigrationResult.success(
        'Successfully migrated database to v$targetVersion',
        migrationsRun: successCount,
      );
    } catch (e) {
      AppLogger.error('Migration process failed', error: e);
      return MigrationResult.failure('Migration process failed: ${e.toString()}');
    }
  }

  /// Migrate existing offline data to new format
  Future<void> migrateOfflineData() async {
    try {
      AppLogger.info('Starting offline data migration...');
      
      // Get offline storage service
      final offlineStorage = OfflineStorageService();
      
      // Migrate products
      await _migrateOfflineProducts(offlineStorage);
      
      // Migrate sales
      await _migrateOfflineSales(offlineStorage);
      
      // Migrate stock data
      await _migrateOfflineStock(offlineStorage);
      
      // Clean up old format data
      await _cleanupOldOfflineData(offlineStorage);
      
      AppLogger.info('✅ Offline data migration completed');
    } catch (e) {
      AppLogger.error('Offline data migration failed', error: e);
    }
  }

  /// Import data from CSV files
  Future<ImportResult> importFromCSV({
    required String csvData,
    required String entityType, // 'products', 'customers', 'stock'
    bool overwriteExisting = false,
  }) async {
    try {
      AppLogger.info('Starting CSV import for $entityType');
      
      final lines = csvData.trim().split('\n');
      if (lines.length < 2) {
        return ImportResult.failure('CSV must contain at least headers and one data row');
      }
      
      final headers = lines[0].split(',').map((h) => h.trim()).toList();
      final dataRows = lines.skip(1).map((line) => line.split(',').map((cell) => cell.trim()).toList()).toList();
      
      int successCount = 0;
      int failCount = 0;
      final errors = <String>[];
      
      for (int i = 0; i < dataRows.length; i++) {
        try {
          final rowData = Map.fromIterables(headers, dataRows[i]);
          
          switch (entityType) {
            case 'products':
              await _importProduct(rowData, overwriteExisting);
              break;
            case 'customers':
              await _importCustomer(rowData, overwriteExisting);
              break;
            case 'stock':
              await _importStock(rowData, overwriteExisting);
              break;
            default:
              throw Exception('Unsupported entity type: $entityType');
          }
          
          successCount++;
        } catch (e) {
          failCount++;
          errors.add('Row ${i + 2}: ${e.toString()}');
          AppLogger.warning('Failed to import row ${i + 2}', error: e);
        }
      }
      
      AppLogger.info('CSV import completed: $successCount successful, $failCount failed');
      return ImportResult.success(
        successCount: successCount,
        failCount: failCount,
        errors: errors,
      );
    } catch (e) {
      AppLogger.error('CSV import failed', error: e);
      return ImportResult.failure(e.toString());
    }
  }

  /// Export data to CSV format
  Future<String> exportToCSV({
    required String entityType,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  }) async {
    try {
      List<Map<String, dynamic>> data;
      List<String> columns;
      
      switch (entityType) {
        case 'products':
          data = await _getProductsForExport(filters);
          columns = ['product_code', 'product_name', 'category', 'price', 'stock_quantity', 'created_at'];
          break;
        case 'sales':
          data = await _getSalesForExport(startDate, endDate, filters);
          columns = ['sale_date', 'product_name', 'customer_name', 'quantity', 'unit_price', 'total_amount', 'status'];
          break;
        case 'customers':
          data = await _getCustomersForExport(filters);
          columns = ['customer_code', 'first_name', 'last_name', 'email', 'phone', 'total_orders', 'total_spent'];
          break;
        case 'stock':
          data = await _getStockForExport(filters);
          columns = ['product_code', 'product_name', 'location', 'quantity', 'threshold', 'last_updated'];
          break;
        default:
          throw Exception('Unsupported entity type: $entityType');
      }
      
      // Generate CSV
      final csv = StringBuffer();
      csv.writeln(columns.join(','));
      
      for (final row in data) {
        final values = columns.map((col) => _escapeCsvValue(row[col]?.toString() ?? '')).toList();
        csv.writeln(values.join(','));
      }
      
      return csv.toString();
    } catch (e) {
      AppLogger.error('CSV export failed', error: e);
      rethrow;
    }
  }

  Future<int> _getCurrentSchemaVersion() async {
    try {
      final result = await _supabase
          .from('system_settings')
          .select('value')
          .eq('key', 'schema_version')
          .single();
      return int.parse(result['value']);
    } catch (e) {
      // If table doesn't exist or no version found, assume version 0
      return 0;
    }
  }

  Future<int> _getTargetSchemaVersion() async {
    // This would be defined in your app configuration
    return 3; // Current target version
  }

  Future<List<Migration>> _getPendingMigrations(int currentVersion, int targetVersion) async {
    // Define your migrations here
    final allMigrations = [
      Migration(
        version: 1,
        name: 'add_enhanced_product_fields',
        sql: '''
          ALTER TABLE products 
          ADD COLUMN IF NOT EXISTS product_code TEXT,
          ADD COLUMN IF NOT EXISTS dimensions JSONB,
          ADD COLUMN IF NOT EXISTS materials JSONB;
        ''',
      ),
      Migration(
        version: 2,
        name: 'create_product_categories',
        sql: '''
          CREATE TABLE IF NOT EXISTS product_categories (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            name TEXT NOT NULL,
            slug TEXT UNIQUE NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW()
          );
        ''',
      ),
      Migration(
        version: 3,
        name: 'enhance_sales_table',
        sql: '''
          ALTER TABLE sales 
          ADD COLUMN IF NOT EXISTS customer_id UUID,
          ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0.00;
        ''',
      ),
    ];
    
    return allMigrations.where((m) => m.version > currentVersion && m.version <= targetVersion).toList();
  }

  Future<void> _runSingleMigration(Migration migration) async {
    await _supabase.rpc('execute_sql', params: {'sql': migration.sql});
  }

  Future<void> _updateSchemaVersion(int version) async {
    await _supabase.from('system_settings').upsert({
      'key': 'schema_version',
      'value': version.toString(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _migrateOfflineProducts(OfflineStorageService storage) async {
    // Implementation for migrating offline product data
    // This would handle format changes in locally stored product data
  }

  Future<void> _migrateOfflineSales(OfflineStorageService storage) async {
    // Implementation for migrating offline sales data
  }

  Future<void> _migrateOfflineStock(OfflineStorageService storage) async {
    // Implementation for migrating offline stock data
  }

  Future<void> _cleanupOldOfflineData(OfflineStorageService storage) async {
    // Clean up old format data after successful migration
  }

  Future<void> _importProduct(Map<String, String> rowData, bool overwrite) async {
    final productData = {
      'product_code': rowData['product_code'],
      'product_name': rowData['product_name'],
      'product_type': rowData['product_type'] ?? 'furniture',
      'price': double.tryParse(rowData['price'] ?? '0') ?? 0.0,
      'description': rowData['description'],
      'low_stock_threshold': int.tryParse(rowData['low_stock_threshold'] ?? '10') ?? 10,
    };

    if (overwrite) {
      await _supabase.from('products').upsert(productData);
    } else {
      await _supabase.from('products').insert(productData);
    }
  }

  Future<void> _importCustomer(Map<String, String> rowData, bool overwrite) async {
    // Implementation for customer import
  }

  Future<void> _importStock(Map<String, String> rowData, bool overwrite) async {
    // Implementation for stock import
  }

  Future<List<Map<String, dynamic>>> _getProductsForExport(Map<String, dynamic>? filters) async {
    var query = _supabase.from('products').select('''
      product_code, product_name, price, created_at,
      product_categories(name),
      stocks(quantity)
    ''');

    if (filters != null) {
      // Apply filters
      if (filters['category_id'] != null) {
        query = query.eq('category_id', filters['category_id']);
      }
    }

    return await query;
  }

  Future<List<Map<String, dynamic>>> _getSalesForExport(
    DateTime? startDate, 
    DateTime? endDate, 
    Map<String, dynamic>? filters
  ) async {
    var query = _supabase.from('sales').select('*');

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    return await query.order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> _getCustomersForExport(Map<String, dynamic>? filters) async {
    return await _supabase.from('customers').select('*').order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> _getStockForExport(Map<String, dynamic>? filters) async {
    return await _supabase.from('stocks').select('''
      *, 
      products(product_code, product_name, low_stock_threshold),
      stock_locations(location_name)
    ''').order('updated_at', ascending: false);
  }

  String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

// Supporting classes
class Migration {
  final int version;
  final String name;
  final String sql;

  Migration({
    required this.version,
    required this.name,
    required this.sql,
  });
}

class MigrationResult {
  final bool success;
  final String message;
  final int migrationsRun;

  MigrationResult._({
    required this.success,
    required this.message,
    this.migrationsRun = 0,
  });

  factory MigrationResult.success(String message, {int migrationsRun = 0}) =>
      MigrationResult._(success: true, message: message, migrationsRun: migrationsRun);

  factory MigrationResult.failure(String message, {int successCount = 0}) =>
      MigrationResult._(success: false, message: message, migrationsRun: successCount);
}

class ImportResult {
  final bool success;
  final String? message;
  final int successCount;
  final int failCount;
  final List<String> errors;

  ImportResult._({
    required this.success,
    this.message,
    this.successCount = 0,
    this.failCount = 0,
    this.errors = const [],
  });

  factory ImportResult.success({
    required int successCount,
    int failCount = 0,
    List<String> errors = const [],
  }) =>
      ImportResult._(
        success: true,
        successCount: successCount,
        failCount: failCount,
        errors: errors,
      );

  factory ImportResult.failure(String message) =>
      ImportResult._(success: false, message: message);
}
```

---

## Implementation Timeline

### Phase 1: Foundation (Weeks 1-2)
- Enhanced database schema deployment
- Advanced RLS policies implementation
- Basic realtime subscriptions setup
- File storage configuration

### Phase 2: Core Integrations (Weeks 3-4) 
- Enhanced Steadfast courier integration
- OneSignal rich notifications
- PDF generation (server-side functions)
- Image optimization pipeline

### Phase 3: Advanced Features (Weeks 5-6)
- Production management system
- Customer relationship management
- Advanced reporting system
- Data migration utilities

### Phase 4: Optimization & Testing (Weeks 7-8)
- Performance optimization
- Security audit and hardening  
- Comprehensive testing
- Documentation and training

---

## Performance & Security Considerations

### Database Optimization
- **Indexing Strategy**: Comprehensive indexes on frequently queried columns
- **Query Optimization**: Use materialized views for complex reporting queries
- **Connection Pooling**: Configure optimal connection limits
- **Partitioning**: Consider partitioning large tables by date ranges

### Security Measures
- **Data Encryption**: All sensitive data encrypted at rest and in transit
- **Audit Logging**: Complete audit trail for all data modifications
- **Backup Strategy**: Automated daily backups with point-in-time recovery
- **Access Control**: Principle of least privilege with regular access reviews

### Scalability Planning
- **Horizontal Scaling**: Design for multi-tenant architecture
- **Caching Strategy**: Redis caching for frequently accessed data
- **CDN Integration**: Cloudflare for global asset delivery
- **Monitoring**: Comprehensive application and database monitoring

This comprehensive backend integration strategy provides a robust foundation for scaling FurniShop Manager into a production-ready enterprise application with advanced features, security, and performance optimization.