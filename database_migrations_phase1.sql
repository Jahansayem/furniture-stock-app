-- ==========================================
-- FURNISHOP MANAGER - PHASE 1 DATABASE MIGRATIONS
-- Enhanced Schema Implementation
-- ==========================================

-- Execute this script in Supabase SQL Editor
-- Run sections individually to monitor progress

BEGIN;

-- ==========================================
-- 1. ENHANCED USER ROLES AND PERMISSIONS
-- ==========================================

-- Create comprehensive user roles table
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    role_name TEXT UNIQUE NOT NULL,
    role_level INTEGER NOT NULL CHECK (role_level BETWEEN 1 AND 5),
    permissions JSONB NOT NULL DEFAULT '{}',
    can_manage_roles TEXT[] DEFAULT '{}',
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default role hierarchy
INSERT INTO user_roles (role_name, role_level, permissions, can_manage_roles, description) VALUES
(
    'super_admin', 1, 
    '{"products": {"create": true, "read": true, "update": true, "delete": true, "bulk_import": true, "export": true}, "orders": {"create": true, "read": true, "update": true, "delete": true, "cancel": true, "refund": true, "export": true}, "customers": {"create": true, "read": true, "update": true, "delete": true, "export": true}, "reports": {"all_reports": true, "financial": true, "inventory": true, "sales": true, "user_activity": true}, "settings": {"system": true, "users": true, "roles": true, "integrations": true}, "locations": {"all": true}}',
    '{"admin", "manager", "staff", "viewer"}',
    'Full system access with user management capabilities'
),
(
    'admin', 2,
    '{"products": {"create": true, "read": true, "update": true, "delete": true, "export": true}, "orders": {"create": true, "read": true, "update": true, "cancel": true, "refund": true, "export": true}, "customers": {"create": true, "read": true, "update": true, "export": true}, "reports": {"financial": true, "inventory": true, "sales": true}, "settings": {"users": true, "basic_settings": true}, "locations": {"all": true}}',
    '{"manager", "staff", "viewer"}',
    'Administrative access with business management capabilities'
),
(
    'manager', 3,
    '{"products": {"read": true, "update": true, "export": true}, "orders": {"create": true, "read": true, "update": true, "export": true}, "customers": {"create": true, "read": true, "update": true}, "reports": {"inventory": true, "sales": true, "own_team": true}, "settings": {"location_settings": true}, "locations": {"assigned_only": true}}',
    '{"staff", "viewer"}',
    'Location management with team supervision'
),
(
    'staff', 4,
    '{"products": {"read": true, "update_stock": true}, "orders": {"create": true, "read": true, "update_own": true}, "customers": {"read": true, "create": true}, "reports": {"basic_sales": true}, "locations": {"assigned_only": true}}',
    '{}',
    'Operational staff with order and inventory management'
),
(
    'viewer', 5,
    '{"products": {"read": true}, "orders": {"read": true}, "customers": {"read": true}, "reports": {"basic_inventory": true}}',
    '{}',
    'Read-only access for reporting and viewing'
)
ON CONFLICT (role_name) DO UPDATE SET
    permissions = EXCLUDED.permissions,
    can_manage_roles = EXCLUDED.can_manage_roles,
    description = EXCLUDED.description,
    updated_at = NOW();

-- Enhance user_profiles with role-based features
ALTER TABLE user_profiles 
    ADD COLUMN IF NOT EXISTS role_permissions JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS department TEXT DEFAULT 'general',
    ADD COLUMN IF NOT EXISTS manager_id UUID REFERENCES user_profiles(id),
    ADD COLUMN IF NOT EXISTS location_access TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS feature_access TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS salary DECIMAL(10,2),
    ADD COLUMN IF NOT EXISTS hire_date DATE,
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS last_activity TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS login_attempts INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{}';

-- Update existing users with default role permissions
UPDATE user_profiles SET 
    role_permissions = (
        SELECT permissions FROM user_roles WHERE role_name = user_profiles.role
    ),
    is_active = TRUE,
    last_activity = NOW()
WHERE role_permissions IS NULL OR role_permissions = '{}';

-- ==========================================
-- 2. PRODUCT CATEGORIES AND VARIANTS
-- ==========================================

-- Product categories with hierarchy support
CREATE TABLE IF NOT EXISTS product_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id UUID REFERENCES product_categories(id) ON DELETE CASCADE,
    description TEXT,
    image_url TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    seo_slug TEXT UNIQUE,
    meta_description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default furniture categories
INSERT INTO product_categories (name, description, sort_order, seo_slug) VALUES
('Living Room', 'Furniture for living spaces including sofas, tables, and entertainment units', 1, 'living-room'),
('Bedroom', 'Bedroom furniture including beds, wardrobes, and dressers', 2, 'bedroom'),
('Dining Room', 'Dining furniture including tables, chairs, and cabinets', 3, 'dining-room'),
('Office', 'Office furniture including desks, chairs, and storage', 4, 'office'),
('Outdoor', 'Outdoor and patio furniture', 5, 'outdoor'),
('Storage', 'Storage solutions and organizational furniture', 6, 'storage'),
('Accessories', 'Home accessories and decor items', 7, 'accessories')
ON CONFLICT (seo_slug) DO NOTHING;

-- Product variants for different options
CREATE TABLE IF NOT EXISTS product_variants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    variant_name TEXT NOT NULL,
    sku TEXT UNIQUE,
    price_adjustment DECIMAL(10,2) DEFAULT 0,
    cost_adjustment DECIMAL(10,2) DEFAULT 0,
    attributes JSONB DEFAULT '{}', -- color, size, material variations
    image_urls TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enhance products table with additional fields
ALTER TABLE products 
    ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES product_categories(id),
    ADD COLUMN IF NOT EXISTS brand TEXT,
    ADD COLUMN IF NOT EXISTS model TEXT,
    ADD COLUMN IF NOT EXISTS sku TEXT UNIQUE,
    ADD COLUMN IF NOT EXISTS dimensions JSONB DEFAULT '{}', -- {width, height, depth, weight}
    ADD COLUMN IF NOT EXISTS materials TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS colors TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS finish_options TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS warranty_period INTEGER DEFAULT 12, -- months
    ADD COLUMN IF NOT EXISTS supplier_info JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS manufacturing_cost DECIMAL(10,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS margin_percentage DECIMAL(5,2) DEFAULT 25,
    ADD COLUMN IF NOT EXISTS status TEXT CHECK (status IN ('active', 'discontinued', 'draft', 'out_of_stock')) DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS seo_tags TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS bulk_discount_rules JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS minimum_order_quantity INTEGER DEFAULT 1,
    ADD COLUMN IF NOT EXISTS maximum_order_quantity INTEGER,
    ADD COLUMN IF NOT EXISTS lead_time_days INTEGER DEFAULT 0;

-- Update existing products with default category
UPDATE products SET 
    category_id = (SELECT id FROM product_categories WHERE name = 'Living Room' LIMIT 1),
    status = 'active',
    margin_percentage = 25,
    minimum_order_quantity = 1
WHERE category_id IS NULL;

-- ==========================================
-- 3. CUSTOMER MANAGEMENT SYSTEM
-- ==========================================

-- Comprehensive customer management
CREATE TABLE IF NOT EXISTS customers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_code TEXT UNIQUE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    address TEXT,
    location POINT, -- PostGIS point for latitude/longitude
    city TEXT,
    area TEXT,
    postal_code TEXT,
    customer_type TEXT CHECK (customer_type IN ('individual', 'business', 'wholesale', 'vip')) DEFAULT 'individual',
    credit_limit DECIMAL(10,2) DEFAULT 0,
    current_balance DECIMAL(10,2) DEFAULT 0,
    payment_terms TEXT DEFAULT 'cash_on_delivery',
    preferred_delivery_time TEXT,
    special_instructions TEXT,
    notes TEXT,
    tags TEXT[] DEFAULT '{}',
    source TEXT, -- website, phone, referral, walk-in
    referred_by UUID REFERENCES customers(id),
    assigned_sales_rep UUID REFERENCES user_profiles(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Add search index
    CONSTRAINT unique_phone_active UNIQUE(phone) WHERE is_active = true
);

-- Customer analytics and behavior tracking
CREATE TABLE IF NOT EXISTS customer_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE UNIQUE,
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0,
    average_order_value DECIMAL(10,2) DEFAULT 0,
    last_order_date TIMESTAMPTZ,
    first_order_date TIMESTAMPTZ,
    favorite_categories TEXT[] DEFAULT '{}',
    preferred_products JSONB DEFAULT '{}',
    loyalty_points INTEGER DEFAULT 0,
    loyalty_tier TEXT DEFAULT 'bronze',
    churn_risk TEXT CHECK (churn_risk IN ('low', 'medium', 'high')) DEFAULT 'low',
    lifetime_value DECIMAL(12,2) DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 4. ENHANCED ORDER MANAGEMENT
-- ==========================================

-- Comprehensive order system (enhanced from sales table)
CREATE TABLE IF NOT EXISTS orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_number TEXT UNIQUE NOT NULL,
    customer_id UUID REFERENCES customers(id),
    order_type TEXT CHECK (order_type IN ('online_cod', 'offline', 'wholesale', 'showroom', 'phone_order')) NOT NULL,
    status TEXT CHECK (status IN (
        'draft', 'pending', 'confirmed', 'processing', 'ready_to_ship', 
        'shipped', 'out_for_delivery', 'delivered', 'completed', 
        'cancelled', 'returned', 'refunded', 'on_hold'
    )) DEFAULT 'pending',
    
    -- Customer information (denormalized for performance)
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_email TEXT,
    billing_address TEXT,
    shipping_address TEXT NOT NULL,
    customer_location POINT, -- delivery location
    
    -- Financial details
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    discount_type TEXT CHECK (discount_type IN ('percentage', 'fixed')),
    tax_amount DECIMAL(10,2) DEFAULT 0,
    delivery_charge DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    advance_payment DECIMAL(10,2) DEFAULT 0,
    due_amount DECIMAL(10,2) DEFAULT 0,
    
    -- Delivery information
    delivery_date DATE,
    delivery_time_slot TEXT,
    delivery_method TEXT DEFAULT 'home_delivery',
    special_instructions TEXT,
    
    -- Workflow management
    assigned_to UUID REFERENCES user_profiles(id),
    priority TEXT CHECK (priority IN ('low', 'normal', 'high', 'urgent')) DEFAULT 'normal',
    source TEXT DEFAULT 'manual', -- website, phone, app, walk-in
    sales_channel TEXT DEFAULT 'direct',
    
    -- Internal tracking
    estimated_completion_date DATE,
    actual_completion_date DATE,
    notes TEXT,
    internal_notes TEXT,
    tags TEXT[] DEFAULT '{}',
    
    -- Audit trail
    created_by UUID REFERENCES user_profiles(id),
    updated_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Generate order number trigger
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
    prefix TEXT := 'FS';
    year_month TEXT;
    sequence_num INTEGER;
    new_order_number TEXT;
BEGIN
    year_month := TO_CHAR(NEW.created_at, 'YYMM');
    
    -- Get the next sequence number for this month
    SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM LENGTH(prefix || year_month) + 1) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM orders 
    WHERE order_number LIKE prefix || year_month || '%';
    
    new_order_number := prefix || year_month || LPAD(sequence_num::TEXT, 4, '0');
    NEW.order_number := new_order_number;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_generate_order_number ON orders;
CREATE TRIGGER trigger_generate_order_number
    BEFORE INSERT ON orders
    FOR EACH ROW
    WHEN (NEW.order_number IS NULL OR NEW.order_number = '')
    EXECUTE FUNCTION generate_order_number();

-- Order items with detailed tracking
CREATE TABLE IF NOT EXISTS order_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    product_variant_id UUID REFERENCES product_variants(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    line_total DECIMAL(10,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    
    -- Product snapshot at time of order
    product_snapshot JSONB DEFAULT '{}',
    customization_details TEXT,
    special_requirements TEXT,
    
    -- Production tracking
    production_status TEXT DEFAULT 'pending',
    estimated_completion_date DATE,
    actual_completion_date DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Order status history for complete tracking
CREATE TABLE IF NOT EXISTS order_status_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    from_status TEXT,
    to_status TEXT NOT NULL,
    changed_by UUID REFERENCES user_profiles(id),
    reason TEXT,
    notes TEXT,
    estimated_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create status history trigger
CREATE OR REPLACE FUNCTION track_order_status_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO order_status_history (order_id, to_status, changed_by, notes)
        VALUES (NEW.id, NEW.status, NEW.created_by, 'Order created');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history (order_id, from_status, to_status, changed_by, notes)
        VALUES (NEW.id, OLD.status, NEW.status, NEW.updated_by, 'Status changed');
        RETURN NEW;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_track_order_status ON orders;
CREATE TRIGGER trigger_track_order_status
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION track_order_status_changes();

-- ==========================================
-- 5. ENHANCED STOCK MANAGEMENT
-- ==========================================

-- Enhance stock locations
ALTER TABLE stock_locations 
    ADD COLUMN IF NOT EXISTS parent_location_id UUID REFERENCES stock_locations(id),
    ADD COLUMN IF NOT EXISTS location_code TEXT UNIQUE,
    ADD COLUMN IF NOT EXISTS manager_id UUID REFERENCES user_profiles(id),
    ADD COLUMN IF NOT EXISTS contact_phone TEXT,
    ADD COLUMN IF NOT EXISTS contact_email TEXT,
    ADD COLUMN IF NOT EXISTS operating_hours JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS storage_capacity INTEGER DEFAULT 1000,
    ADD COLUMN IF NOT EXISTS current_utilization INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS location_coordinates POINT,
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{}';

-- Generate location codes for existing locations
UPDATE stock_locations SET 
    location_code = 'LOC' || LPAD((ROW_NUMBER() OVER (ORDER BY created_at))::TEXT, 3, '0'),
    is_active = TRUE
WHERE location_code IS NULL;

-- Enhance stocks with advanced tracking
ALTER TABLE stocks 
    ADD COLUMN IF NOT EXISTS reserved_quantity INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS available_quantity INTEGER GENERATED ALWAYS AS (quantity - reserved_quantity) STORED,
    ADD COLUMN IF NOT EXISTS minimum_stock INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS maximum_stock INTEGER DEFAULT 1000,
    ADD COLUMN IF NOT EXISTS reorder_point INTEGER DEFAULT 10,
    ADD COLUMN IF NOT EXISTS reorder_quantity INTEGER DEFAULT 50,
    ADD COLUMN IF NOT EXISTS average_cost DECIMAL(10,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_value DECIMAL(12,2) GENERATED ALWAYS AS (quantity * average_cost) STORED,
    ADD COLUMN IF NOT EXISTS last_stock_take_date DATE,
    ADD COLUMN IF NOT EXISTS last_movement_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS bin_location TEXT,
    ADD COLUMN IF NOT EXISTS notes TEXT;

-- Stock reservations for order management
CREATE TABLE IF NOT EXISTS stock_reservations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    product_variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    location_id UUID REFERENCES stock_locations(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    order_item_id UUID REFERENCES order_items(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    reserved_until TIMESTAMPTZ NOT NULL,
    status TEXT CHECK (status IN ('active', 'expired', 'fulfilled', 'cancelled')) DEFAULT 'active',
    created_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(product_id, product_variant_id, location_id, order_id)
);

-- Enhanced stock movements
CREATE TABLE IF NOT EXISTS stock_movements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    product_variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    location_id UUID REFERENCES stock_locations(id) ON DELETE CASCADE,
    movement_type TEXT CHECK (movement_type IN (
        'in', 'out', 'transfer_in', 'transfer_out', 'adjustment_positive', 
        'adjustment_negative', 'return', 'damaged', 'sale', 'purchase'
    )) NOT NULL,
    quantity INTEGER NOT NULL,
    
    -- Reference information
    reference_type TEXT, -- order, purchase, transfer, adjustment, return
    reference_id UUID,
    reference_number TEXT,
    
    -- Financial tracking
    unit_cost DECIMAL(10,2) DEFAULT 0,
    total_cost DECIMAL(10,2) DEFAULT 0,
    
    -- Additional details
    reason TEXT,
    batch_number TEXT,
    expiry_date DATE,
    supplier_info TEXT,
    
    -- Approval workflow
    performed_by UUID REFERENCES user_profiles(id),
    approved_by UUID REFERENCES user_profiles(id),
    approved_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 6. COURIER AND LOGISTICS
-- ==========================================

-- Courier service management
CREATE TABLE IF NOT EXISTS courier_services (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_name TEXT UNIQUE NOT NULL,
    service_code TEXT UNIQUE NOT NULL,
    api_endpoint TEXT,
    api_credentials JSONB DEFAULT '{}',
    supported_areas TEXT[] DEFAULT '{}',
    pricing_rules JSONB DEFAULT '{}',
    delivery_time_estimates JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    is_cod_supported BOOLEAN DEFAULT TRUE,
    settings JSONB DEFAULT '{}',
    contact_info JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert Steadfast as default courier
INSERT INTO courier_services (service_name, service_code, is_active, is_cod_supported, settings) VALUES
('Steadfast Courier', 'STEADFAST', true, true, '{"auto_create_orders": true, "webhook_enabled": true}')
ON CONFLICT (service_code) DO UPDATE SET
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

-- Delivery tracking and management
CREATE TABLE IF NOT EXISTS deliveries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    courier_service_id UUID REFERENCES courier_services(id),
    consignment_id TEXT,
    tracking_code TEXT,
    
    -- Delivery details
    delivery_status TEXT DEFAULT 'pending',
    pickup_date DATE,
    estimated_delivery_date DATE,
    actual_delivery_date DATE,
    delivery_attempts INTEGER DEFAULT 0,
    
    -- Financial
    delivery_charge DECIMAL(10,2) DEFAULT 0,
    cod_amount DECIMAL(10,2) DEFAULT 0,
    cod_collected_amount DECIMAL(10,2) DEFAULT 0,
    
    -- Address information
    pickup_address TEXT,
    delivery_address TEXT NOT NULL,
    recipient_name TEXT NOT NULL,
    recipient_phone TEXT NOT NULL,
    
    -- Additional details
    delivery_instructions TEXT,
    delivery_notes TEXT,
    proof_of_delivery_url TEXT,
    signature_url TEXT,
    delivered_to_person TEXT,
    
    -- Internal tracking
    last_status_check TIMESTAMPTZ,
    status_history JSONB DEFAULT '[]',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(consignment_id, courier_service_id)
);

-- ==========================================
-- 7. FINANCIAL MANAGEMENT
-- ==========================================

-- Payment tracking
CREATE TABLE IF NOT EXISTS payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id),
    customer_id UUID REFERENCES customers(id),
    payment_reference TEXT UNIQUE,
    
    payment_type TEXT CHECK (payment_type IN (
        'cash', 'card', 'bank_transfer', 'mobile_banking', 'cod', 
        'check', 'advance', 'partial', 'refund'
    )) NOT NULL,
    
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    currency TEXT DEFAULT 'BDT',
    exchange_rate DECIMAL(10,6) DEFAULT 1,
    
    -- Payment method details
    payment_method_details JSONB DEFAULT '{}',
    transaction_id TEXT,
    gateway_response JSONB DEFAULT '{}',
    
    payment_status TEXT CHECK (payment_status IN (
        'pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'
    )) DEFAULT 'pending',
    
    payment_date TIMESTAMPTZ DEFAULT NOW(),
    due_date DATE,
    
    -- Processing details
    processed_by UUID REFERENCES user_profiles(id),
    approved_by UUID REFERENCES user_profiles(id),
    notes TEXT,
    receipt_url TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Expense tracking
CREATE TABLE IF NOT EXISTS expenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    expense_number TEXT UNIQUE,
    category TEXT NOT NULL,
    subcategory TEXT,
    description TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    currency TEXT DEFAULT 'BDT',
    
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method TEXT,
    vendor_name TEXT,
    reference_number TEXT,
    
    -- Approval workflow
    status TEXT CHECK (status IN ('draft', 'pending', 'approved', 'rejected', 'paid')) DEFAULT 'draft',
    requested_by UUID REFERENCES user_profiles(id),
    approved_by UUID REFERENCES user_profiles(id),
    approval_date TIMESTAMPTZ,
    rejection_reason TEXT,
    
    -- Documentation
    receipt_urls TEXT[] DEFAULT '{}',
    supporting_documents TEXT[] DEFAULT '{}',
    
    -- Tax and accounting
    is_tax_deductible BOOLEAN DEFAULT FALSE,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 8. PERFORMANCE INDEXES
-- ==========================================

-- User profiles indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_role_active ON user_profiles(role, is_active);
CREATE INDEX IF NOT EXISTS idx_user_profiles_manager ON user_profiles(manager_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_location_access ON user_profiles USING gin(location_access);

-- Products indexes
CREATE INDEX IF NOT EXISTS idx_products_category_status ON products(category_id, status);
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku) WHERE sku IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_featured ON products(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_products_search ON products USING gin(to_tsvector('english', product_name || ' ' || COALESCE(description, '')));

-- Orders indexes
CREATE INDEX IF NOT EXISTS idx_orders_status_date ON orders(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_customer_phone ON orders(customer_phone);
CREATE INDEX IF NOT EXISTS idx_orders_assigned_user ON orders(assigned_to, status);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);

-- Order items indexes
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Stock indexes
CREATE INDEX IF NOT EXISTS idx_stocks_product_location ON stocks(product_id, location_id);
CREATE INDEX IF NOT EXISTS idx_stocks_low_stock ON stocks(product_id) WHERE quantity <= reorder_point;
CREATE INDEX IF NOT EXISTS idx_stocks_available ON stocks(available_quantity) WHERE available_quantity > 0;

-- Stock movements indexes
CREATE INDEX IF NOT EXISTS idx_stock_movements_product_date ON stock_movements(product_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stock_movements_location ON stock_movements(location_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stock_movements_reference ON stock_movements(reference_type, reference_id);

-- Customers indexes
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_customers_type ON customers(customer_type, is_active);
CREATE INDEX IF NOT EXISTS idx_customers_search ON customers USING gin(to_tsvector('english', name || ' ' || phone));

-- Payments indexes
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_status_date ON payments(payment_status, payment_date DESC);

-- Deliveries indexes
CREATE INDEX IF NOT EXISTS idx_deliveries_order_id ON deliveries(order_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_status ON deliveries(delivery_status);
CREATE INDEX IF NOT EXISTS idx_deliveries_consignment ON deliveries(consignment_id) WHERE consignment_id IS NOT NULL;

-- ==========================================
-- 9. ROW LEVEL SECURITY POLICIES
-- ==========================================

-- Enable RLS on all new tables
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE courier_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- User roles policies (admin only)
CREATE POLICY "user_roles_admin_only" ON user_roles
    FOR ALL TO authenticated
    USING ((SELECT role FROM user_profiles WHERE id = auth.uid()) IN ('super_admin', 'admin'));

-- Orders policies with role-based access
CREATE POLICY "orders_access_policy" ON orders
    FOR ALL TO authenticated
    USING (
        (SELECT role FROM user_profiles WHERE id = auth.uid()) IN ('super_admin', 'admin')
        OR
        (SELECT role FROM user_profiles WHERE id = auth.uid()) = 'manager' 
        AND EXISTS (
            SELECT 1 FROM user_profiles up 
            WHERE up.id = auth.uid() 
            AND (up.location_access = '{}' OR up.location_access @> ARRAY[orders.id::text])
        )
        OR
        assigned_to = auth.uid()
        OR
        created_by = auth.uid()
    );

-- Customers policy
CREATE POLICY "customers_access_policy" ON customers
    FOR ALL TO authenticated
    USING (
        (SELECT role FROM user_profiles WHERE id = auth.uid()) IN ('super_admin', 'admin', 'manager', 'staff')
    );

-- Products policy (all authenticated users can read)
CREATE POLICY "products_read_all" ON products
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "products_modify_authorized" ON products
    FOR ALL TO authenticated
    USING (
        (SELECT role FROM user_profiles WHERE id = auth.uid()) IN ('super_admin', 'admin', 'manager')
    );

-- Stock movements policy
CREATE POLICY "stock_movements_access" ON stock_movements
    FOR ALL TO authenticated
    USING (
        (SELECT role FROM user_profiles WHERE id = auth.uid()) IN ('super_admin', 'admin')
        OR
        performed_by = auth.uid()
        OR
        (SELECT role FROM user_profiles WHERE id = auth.uid()) IN ('manager', 'staff')
    );

-- Payments policy
CREATE POLICY "payments_access" ON payments
    FOR ALL TO authenticated
    USING (
        (SELECT role FROM user_profiles WHERE id = auth.uid()) IN ('super_admin', 'admin')
        OR
        processed_by = auth.uid()
        OR
        EXISTS (
            SELECT 1 FROM orders o 
            WHERE o.id = payments.order_id 
            AND (o.created_by = auth.uid() OR o.assigned_to = auth.uid())
        )
    );

-- ==========================================
-- 10. FUNCTIONS AND VIEWS
-- ==========================================

-- Function to get user permissions
CREATE OR REPLACE FUNCTION get_user_permissions(user_id UUID)
RETURNS JSONB AS $$
DECLARE
    user_role TEXT;
    role_permissions JSONB;
BEGIN
    SELECT role INTO user_role
    FROM user_profiles 
    WHERE id = user_id;
    
    SELECT permissions INTO role_permissions
    FROM user_roles 
    WHERE role_name = user_role;
    
    RETURN COALESCE(role_permissions, '{}');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Dashboard statistics view
CREATE OR REPLACE VIEW dashboard_stats AS
SELECT 
    (SELECT COUNT(*) FROM orders WHERE status IN ('pending', 'confirmed')) as pending_orders,
    (SELECT COUNT(*) FROM orders WHERE created_at >= CURRENT_DATE) as today_orders,
    (SELECT SUM(total_amount) FROM orders WHERE created_at >= CURRENT_DATE) as today_sales,
    (SELECT COUNT(*) FROM products WHERE status = 'active') as active_products,
    (SELECT COUNT(*) FROM stocks WHERE quantity <= reorder_point) as low_stock_items,
    (SELECT COUNT(*) FROM customers WHERE is_active = true) as total_customers,
    (SELECT AVG(total_amount) FROM orders WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as avg_order_value;

-- Inventory summary view
CREATE OR REPLACE VIEW inventory_summary AS
SELECT 
    p.id,
    p.product_name,
    p.sku,
    pc.name as category_name,
    p.price,
    p.status,
    COALESCE(SUM(s.quantity), 0) as total_stock,
    COALESCE(SUM(s.reserved_quantity), 0) as total_reserved,
    COALESCE(SUM(s.available_quantity), 0) as total_available,
    COALESCE(SUM(s.total_value), 0) as total_value,
    p.reorder_point,
    CASE 
        WHEN COALESCE(SUM(s.quantity), 0) <= p.low_stock_threshold THEN 'low'
        WHEN COALESCE(SUM(s.quantity), 0) = 0 THEN 'out'
        ELSE 'good'
    END as stock_status
FROM products p
LEFT JOIN product_categories pc ON p.category_id = pc.id
LEFT JOIN stocks s ON p.id = s.product_id
WHERE p.status = 'active'
GROUP BY p.id, p.product_name, p.sku, pc.name, p.price, p.status, p.reorder_point, p.low_stock_threshold;

COMMIT;

-- ==========================================
-- MIGRATION LOG
-- ==========================================

-- Create migration log table
CREATE TABLE IF NOT EXISTS migration_log (
    id SERIAL PRIMARY KEY,
    version TEXT NOT NULL,
    description TEXT NOT NULL,
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    applied_by TEXT DEFAULT current_user
);

-- Log this migration
INSERT INTO migration_log (version, description) VALUES
('1.0.0', 'Phase 1 - Enhanced schema implementation with roles, products, orders, customers, and logistics');

-- ==========================================
-- VERIFICATION QUERIES
-- ==========================================
-- Uncomment to verify the migration

-- SELECT 'User Roles' as table_name, COUNT(*) as count FROM user_roles
-- UNION ALL
-- SELECT 'Product Categories', COUNT(*) FROM product_categories
-- UNION ALL  
-- SELECT 'Enhanced User Profiles', COUNT(*) FROM user_profiles WHERE role_permissions IS NOT NULL
-- UNION ALL
-- SELECT 'Orders Table Created', CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'orders') THEN 1 ELSE 0 END
-- UNION ALL
-- SELECT 'Customers Table Created', CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'customers') THEN 1 ELSE 0 END;