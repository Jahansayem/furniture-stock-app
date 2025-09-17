-- ====================================
-- FurniShop Manager v1.1 - Enhanced Database Schema
-- ====================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ====================================
-- USER ROLES & PERMISSIONS SYSTEM
-- ====================================

-- Enhanced user roles with hierarchical permissions
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name TEXT UNIQUE NOT NULL,
    role_level INTEGER CHECK (role_level BETWEEN 1 AND 5) NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '{}',
    can_manage_roles TEXT[] DEFAULT '{}',
    financial_access JSONB DEFAULT '{}',
    location_restrictions TEXT[] DEFAULT '{}',
    feature_restrictions TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default roles
INSERT INTO user_roles (role_name, role_level, display_name, description, permissions, can_manage_roles, financial_access) VALUES
('owner', 1, 'Owner', 'Full system access with financial control', 
 '{"products": {"create": true, "read": true, "update": true, "delete": true}, "orders": {"create": true, "read": true, "update": true, "delete": true}, "financial": {"view_all": true, "profit_margins": true}, "settings": {"system": true, "users": true}}',
 ARRAY['admin', 'manager', 'employee', 'production_employee'],
 '{"profit_margins": true, "cost_data": true, "salary_data": true}'
),
('admin', 2, 'Administrator', 'Full operational access except owner settings',
 '{"products": {"create": true, "read": true, "update": true, "delete": true}, "orders": {"create": true, "read": true, "update": true}, "financial": {"view_summary": true}}',
 ARRAY['manager', 'employee', 'production_employee'],
 '{"basic_reports": true}'
),
('manager', 3, 'Manager', 'Location management with staff oversight',
 '{"products": {"read": true, "update": true}, "orders": {"create": true, "read": true, "update": true}, "financial": {"view_assigned_location": true}}',
 ARRAY['employee', 'production_employee'],
 '{"location_reports": true}'
),
('employee', 4, 'Employee', 'Sales and basic stock operations',
 '{"products": {"read": true, "update_stock": true}, "orders": {"create": true, "read": true}}',
 ARRAY[]::TEXT[],
 '{}'
),
('production_employee', 5, 'Production Employee', 'Production workflow and material requests',
 '{"products": {"read": true}, "production": {"manage_assigned": true, "material_requests": true}}',
 ARRAY[]::TEXT[],
 '{}'
);

-- Enhanced user profiles with role-based fields
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS role_id UUID REFERENCES user_roles(id);
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS department TEXT DEFAULT 'general';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS manager_id UUID REFERENCES user_profiles(id);
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS location_access TEXT[] DEFAULT '{}';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS financial_permissions JSONB DEFAULT '{}';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS employee_id TEXT UNIQUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS hire_date DATE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS salary DECIMAL(10,2);
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,2) DEFAULT 0;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS shift_schedule JSONB DEFAULT '{}';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS performance_metrics JSONB DEFAULT '{}';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS last_activity TIMESTAMPTZ;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS session_timeout INTEGER DEFAULT 8;

-- Update existing user profiles with default role
UPDATE user_profiles SET role_id = (
    SELECT id FROM user_roles WHERE role_name = 
    CASE 
        WHEN role = 'owner' THEN 'owner'
        WHEN role = 'admin' THEN 'admin'
        WHEN role = 'manager' THEN 'manager'
        WHEN role = 'staff' THEN 'employee'
        ELSE 'employee'
    END
    LIMIT 1
) WHERE role_id IS NULL;

-- ====================================
-- ENHANCED STOCK LOCATIONS (WAREHOUSES)
-- ====================================

-- Enhanced stock locations with warehouse management
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS location_code TEXT UNIQUE;
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS location_type TEXT CHECK (location_type IN ('factory', 'showroom', 'warehouse', 'storage', 'retail')) DEFAULT 'warehouse';
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS parent_location_id UUID REFERENCES stock_locations(id);
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS manager_id UUID REFERENCES user_profiles(id);
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS contact_info JSONB DEFAULT '{}';
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS operating_hours JSONB DEFAULT '{}';
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS storage_capacity INTEGER DEFAULT 1000;
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS current_utilization INTEGER DEFAULT 0;
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS location_coordinates POINT;
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS cost_center_code TEXT;
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS is_sales_enabled BOOLEAN DEFAULT TRUE;
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS is_production_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{}';

-- Update existing locations with codes
UPDATE stock_locations SET 
    location_code = CONCAT('LOC', LPAD(id::text, 3, '0')),
    location_type = CASE 
        WHEN LOWER(location_name) LIKE '%factory%' THEN 'factory'
        WHEN LOWER(location_name) LIKE '%showroom%' THEN 'showroom'
        ELSE 'warehouse'
    END
WHERE location_code IS NULL;

-- ====================================
-- PRODUCT CATEGORIES & VARIANTS
-- ====================================

-- Product categories with hierarchy
CREATE TABLE IF NOT EXISTS product_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    parent_id UUID REFERENCES product_categories(id),
    category_code TEXT UNIQUE,
    description TEXT,
    image_url TEXT,
    margin_percentage DECIMAL(5,2) DEFAULT 25,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    seo_slug TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Product variants (colors, sizes, materials)
CREATE TABLE IF NOT EXISTS product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    variant_name TEXT NOT NULL,
    sku TEXT UNIQUE,
    price_adjustment DECIMAL(10,2) DEFAULT 0,
    cost_adjustment DECIMAL(10,2) DEFAULT 0,
    attributes JSONB DEFAULT '{}',
    image_urls TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enhanced products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES product_categories(id);
ALTER TABLE products ADD COLUMN IF NOT EXISTS brand TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS model TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS sku TEXT UNIQUE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS dimensions JSONB DEFAULT '{}';
ALTER TABLE products ADD COLUMN IF NOT EXISTS materials TEXT[] DEFAULT '{}';
ALTER TABLE products ADD COLUMN IF NOT EXISTS manufacturing_cost DECIMAL(10,2) DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS margin_percentage DECIMAL(5,2) DEFAULT 25;
ALTER TABLE products ADD COLUMN IF NOT EXISTS supplier_info JSONB DEFAULT '{}';
ALTER TABLE products ADD COLUMN IF NOT EXISTS warranty_period INTEGER DEFAULT 12;
ALTER TABLE products ADD COLUMN IF NOT EXISTS status TEXT CHECK (status IN ('active', 'discontinued', 'draft')) DEFAULT 'active';
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS bulk_discount_rules JSONB DEFAULT '{}';
ALTER TABLE products ADD COLUMN IF NOT EXISTS minimum_order_quantity INTEGER DEFAULT 1;
ALTER TABLE products ADD COLUMN IF NOT EXISTS lead_time_days INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS production_complexity TEXT CHECK (production_complexity IN ('simple', 'moderate', 'complex')) DEFAULT 'simple';

-- Update existing products with SKUs
UPDATE products SET sku = CONCAT('PROD', LPAD(id::text, 4, '0')) WHERE sku IS NULL;

-- ====================================
-- ADVANCED STOCK MANAGEMENT
-- ====================================

-- Enhanced stocks table
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS variant_id UUID REFERENCES product_variants(id);
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS reserved_quantity INTEGER DEFAULT 0;
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS available_quantity INTEGER GENERATED ALWAYS AS (quantity - reserved_quantity) STORED;
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS minimum_stock INTEGER DEFAULT 0;
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS maximum_stock INTEGER DEFAULT 1000;
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS reorder_point INTEGER DEFAULT 10;
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS reorder_quantity INTEGER DEFAULT 50;
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS average_cost DECIMAL(10,2) DEFAULT 0;
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS last_cost DECIMAL(10,2) DEFAULT 0;
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS total_value DECIMAL(12,2) GENERATED ALWAYS AS (quantity * COALESCE(average_cost, 0)) STORED;
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS bin_location TEXT;
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS batch_tracking BOOLEAN DEFAULT FALSE;
ALTER TABLE stocks ADD COLUMN IF NOT EXISTS expiry_tracking BOOLEAN DEFAULT FALSE;

-- Stock reservations for order management
CREATE TABLE IF NOT EXISTS stock_reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id),
    variant_id UUID REFERENCES product_variants(id),
    location_id UUID REFERENCES stock_locations(id),
    order_id UUID,
    quantity INTEGER NOT NULL,
    reserved_until TIMESTAMPTZ NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'fulfilled', 'cancelled')),
    created_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================
-- CUSTOMER MANAGEMENT SYSTEM
-- ====================================

-- Comprehensive customer database
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_code TEXT UNIQUE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    address TEXT,
    location POINT,
    city TEXT,
    area TEXT,
    postal_code TEXT,
    customer_type TEXT CHECK (customer_type IN ('individual', 'business', 'wholesale', 'vip')) DEFAULT 'individual',
    
    -- Financial Management
    credit_limit DECIMAL(10,2) DEFAULT 0,
    current_balance DECIMAL(10,2) DEFAULT 0,
    payment_terms TEXT DEFAULT 'cash_on_delivery',
    
    -- Preferences
    preferred_delivery_time TEXT,
    special_instructions TEXT,
    notes TEXT,
    tags TEXT[] DEFAULT '{}',
    
    -- Relationship Management
    source TEXT,
    referred_by UUID REFERENCES customers(id),
    assigned_sales_rep UUID REFERENCES user_profiles(id),
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_phone_active UNIQUE(phone) WHERE is_active = true
);

-- Customer analytics
CREATE TABLE IF NOT EXISTS customer_analytics (
    customer_id UUID REFERENCES customers(id) PRIMARY KEY,
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0,
    average_order_value DECIMAL(10,2) DEFAULT 0,
    last_order_date TIMESTAMPTZ,
    first_order_date TIMESTAMPTZ,
    favorite_categories TEXT[] DEFAULT '{}',
    loyalty_points INTEGER DEFAULT 0,
    loyalty_tier TEXT DEFAULT 'bronze',
    churn_risk TEXT CHECK (churn_risk IN ('low', 'medium', 'high')) DEFAULT 'low',
    lifetime_value DECIMAL(12,2) DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================
-- ENHANCED ORDER MANAGEMENT
-- ====================================

-- Enhanced orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_number TEXT UNIQUE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customers(id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_type TEXT CHECK (order_type IN ('online_cod', 'offline', 'wholesale', 'showroom', 'phone_order'));
ALTER TABLE orders ADD COLUMN IF NOT EXISTS status TEXT CHECK (status IN ('draft', 'pending', 'confirmed', 'processing', 'production', 'ready_to_ship', 'shipped', 'out_for_delivery', 'delivered', 'completed', 'cancelled', 'returned', 'refunded', 'on_hold')) DEFAULT 'pending';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_phone TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_email TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS billing_address TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_address TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_location POINT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS subtotal DECIMAL(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS discount_type TEXT CHECK (discount_type IN ('percentage', 'fixed'));
ALTER TABLE orders ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_charge DECIMAL(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS advance_payment DECIMAL(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS due_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_date DATE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_time_slot TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_method TEXT DEFAULT 'home_delivery';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS special_instructions TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES user_profiles(id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS priority TEXT CHECK (priority IN ('low', 'normal', 'high', 'urgent')) DEFAULT 'normal';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS estimated_completion_date DATE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS actual_completion_date DATE;

-- Generate order numbers for existing orders
UPDATE orders SET order_number = CONCAT('ORD', LPAD(id::text, 6, '0')) WHERE order_number IS NULL;

-- Order items with production tracking
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    variant_id UUID REFERENCES product_variants(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Production Tracking
    production_status TEXT DEFAULT 'pending',
    estimated_completion_date DATE,
    actual_completion_date DATE,
    assigned_production_team UUID REFERENCES user_profiles(id),
    customization_details TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Order status history
CREATE TABLE IF NOT EXISTS order_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    from_status TEXT,
    to_status TEXT NOT NULL,
    changed_by UUID REFERENCES user_profiles(id),
    reason TEXT,
    notes TEXT,
    estimated_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================
-- ENHANCED EMPLOYEE MANAGEMENT
-- ====================================

-- Enhanced attendance with GPS validation
ALTER TABLE attendance_log ADD COLUMN IF NOT EXISTS location_coordinates POINT;
ALTER TABLE attendance_log ADD COLUMN IF NOT EXISTS location_name TEXT;
ALTER TABLE attendance_log ADD COLUMN IF NOT EXISTS is_valid_location BOOLEAN DEFAULT TRUE;
ALTER TABLE attendance_log ADD COLUMN IF NOT EXISTS distance_from_allowed DECIMAL(8,2);
ALTER TABLE attendance_log ADD COLUMN IF NOT EXISTS device_info JSONB DEFAULT '{}';
ALTER TABLE attendance_log ADD COLUMN IF NOT EXISTS shift_type TEXT DEFAULT 'regular';
ALTER TABLE attendance_log ADD COLUMN IF NOT EXISTS overtime_hours DECIMAL(4,2) DEFAULT 0;
ALTER TABLE attendance_log ADD COLUMN IF NOT EXISTS break_duration_minutes INTEGER DEFAULT 0;

-- Employee allowed locations
CREATE TABLE IF NOT EXISTS employee_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES user_profiles(id),
    location_id UUID REFERENCES stock_locations(id),
    allowed_radius_meters INTEGER DEFAULT 500,
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================
-- INDEXES FOR PERFORMANCE
-- ====================================

-- Core indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_stocks_product_location ON stocks(product_id, location_id);
CREATE INDEX IF NOT EXISTS idx_orders_status_date ON orders(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date ON attendance_log(employee_id, check_in_time::DATE);

-- Performance indexes for complex queries
CREATE INDEX IF NOT EXISTS idx_stocks_low_stock ON stocks(product_id) WHERE quantity <= reorder_point;
CREATE INDEX IF NOT EXISTS idx_orders_pending ON orders(status, created_at) WHERE status IN ('pending', 'confirmed', 'processing');
CREATE INDEX IF NOT EXISTS idx_products_active ON products(status, is_featured) WHERE status = 'active';

-- ====================================
-- FUNCTIONS & TRIGGERS
-- ====================================

-- Function to update customer analytics
CREATE OR REPLACE FUNCTION update_customer_analytics()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO customer_analytics (customer_id, total_orders, total_spent, average_order_value, last_order_date, first_order_date)
    SELECT 
        NEW.customer_id,
        COUNT(*),
        SUM(total_amount),
        AVG(total_amount),
        MAX(created_at),
        MIN(created_at)
    FROM orders
    WHERE customer_id = NEW.customer_id AND status NOT IN ('cancelled', 'draft')
    ON CONFLICT (customer_id) DO UPDATE SET
        total_orders = EXCLUDED.total_orders,
        total_spent = EXCLUDED.total_spent,
        average_order_value = EXCLUDED.average_order_value,
        last_order_date = EXCLUDED.last_order_date,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for customer analytics
CREATE TRIGGER trigger_update_customer_analytics
    AFTER INSERT OR UPDATE OF status ON orders
    FOR EACH ROW
    WHEN (NEW.customer_id IS NOT NULL)
    EXECUTE FUNCTION update_customer_analytics();

-- Function to update stock location utilization
CREATE OR REPLACE FUNCTION update_location_utilization()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE stock_locations SET
        current_utilization = (
            SELECT COUNT(*)
            FROM stocks
            WHERE location_id = NEW.location_id AND quantity > 0
        )
    WHERE id = NEW.location_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for location utilization
CREATE TRIGGER trigger_update_location_utilization
    AFTER INSERT OR UPDATE OR DELETE ON stocks
    FOR EACH ROW
    EXECUTE FUNCTION update_location_utilization();

-- ====================================
-- COMPLETION MESSAGE
-- ====================================

-- Add completion confirmation
INSERT INTO public.schema_migrations (version) VALUES ('enhanced_schema_v1.1') ON CONFLICT DO NOTHING;

COMMENT ON TABLE user_roles IS 'Enhanced role-based permission system for FurniShop Manager v1.1';
COMMENT ON TABLE product_categories IS 'Hierarchical product categorization system';
COMMENT ON TABLE customers IS 'Comprehensive customer management with analytics';
COMMENT ON TABLE order_items IS 'Order items with production tracking capabilities';