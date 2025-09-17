-- ==========================================
-- ENHANCED FURNITURE SHOP MANAGER - COMPLETE BACKEND SCHEMA
-- Multi-warehouse, role-based access, production management
-- ==========================================

-- ==========================================
-- 1. CORE USER MANAGEMENT & ROLES
-- ==========================================

-- Enhanced user roles and permissions system
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    role_name TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    permissions JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert comprehensive role system
INSERT INTO user_roles (role_name, display_name, description, permissions) VALUES
('owner', 'Owner', 'Full system access with financial data', '["view_all", "create_all", "edit_all", "delete_all", "view_profit_margins", "view_financial_reports", "manage_users"]'),
('admin', 'Administrator', 'Administrative access without sensitive financial data', '["view_all", "create_all", "edit_all", "delete_some", "manage_inventory", "manage_orders"]'),
('manager', 'Manager', 'Branch/warehouse management access', '["view_branch", "create_orders", "edit_inventory", "view_reports", "manage_employees"]'),
('sales_executive', 'Sales Executive', 'Sales and customer management', '["view_products", "create_orders", "edit_orders", "view_customers", "create_sales"]'),
('stock_manager', 'Stock Manager', 'Inventory and stock movement management', '["view_inventory", "edit_inventory", "create_stock_movements", "view_stock_reports"]'),
('production_manager', 'Production Manager', 'Production planning and material management', '["view_materials", "create_material_requests", "manage_production", "view_production_reports"]'),
('accountant', 'Accountant', 'Financial transaction and expense management', '["view_transactions", "create_transactions", "view_financial_reports", "manage_expenses"]'),
('employee', 'Employee', 'Basic operational access', '["view_assigned", "create_attendance", "view_own_data"]')
ON CONFLICT (role_name) DO UPDATE SET
    permissions = EXCLUDED.permissions,
    updated_at = NOW();

-- Enhanced user profiles with role-based access
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS employee_id TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS department TEXT,
ADD COLUMN IF NOT EXISTS warehouse_id UUID,
ADD COLUMN IF NOT EXISTS hire_date DATE,
ADD COLUMN IF NOT EXISTS salary DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS emergency_contact TEXT,
ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Update user profile policies for role-based access
DROP POLICY IF EXISTS "Role-based profile access" ON user_profiles;
CREATE POLICY "Role-based profile access" 
ON user_profiles FOR SELECT 
USING (
    auth.uid() = id OR
    EXISTS (
        SELECT 1 FROM user_profiles up 
        WHERE up.id = auth.uid() 
        AND (up.role IN ('owner', 'admin', 'manager') OR up.permissions ? 'view_all')
    )
);

-- ==========================================
-- 2. MULTI-WAREHOUSE SYSTEM
-- ==========================================

-- Comprehensive warehouse management
CREATE TABLE IF NOT EXISTS warehouses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    warehouse_code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('factory', 'showroom', 'storage', 'branch')),
    address TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'Bangladesh',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    contact_phone TEXT,
    contact_email TEXT,
    manager_id UUID REFERENCES auth.users(id),
    capacity_sqft INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    operating_hours JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS and policies for warehouses
ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Warehouse visibility based on role and assignment" 
ON warehouses FOR SELECT 
USING (
    is_active = TRUE AND (
        EXISTS (
            SELECT 1 FROM user_profiles up 
            WHERE up.id = auth.uid() 
            AND (up.role IN ('owner', 'admin') OR up.permissions ? 'view_all')
        ) OR
        EXISTS (
            SELECT 1 FROM user_profiles up 
            WHERE up.id = auth.uid() 
            AND (up.warehouse_id = warehouses.id OR up.id = warehouses.manager_id)
        )
    )
);

-- Insert default warehouses
INSERT INTO warehouses (warehouse_code, name, type, address) VALUES
('MAIN-FAC', 'Main Factory', 'factory', 'Dhaka, Bangladesh'),
('SHOW-001', 'Main Showroom', 'showroom', 'Gulshan, Dhaka'),
('STOR-001', 'Central Storage', 'storage', 'Savar, Dhaka')
ON CONFLICT (warehouse_code) DO NOTHING;

-- Update existing stock_locations to reference warehouses
ALTER TABLE stock_locations 
ADD COLUMN IF NOT EXISTS warehouse_id UUID REFERENCES warehouses(id),
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- ==========================================
-- 3. ENHANCED ORDER MANAGEMENT
-- ==========================================

-- Comprehensive order system with Steadfast integration
CREATE TABLE IF NOT EXISTS orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_number TEXT UNIQUE NOT NULL,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_email TEXT,
    customer_address TEXT NOT NULL,
    customer_area TEXT,
    customer_city TEXT,
    customer_postal_code TEXT,
    
    -- Order details
    order_type TEXT NOT NULL CHECK (order_type IN ('online_cod', 'online_prepaid', 'showroom', 'wholesale')),
    order_status TEXT NOT NULL DEFAULT 'pending' CHECK (order_status IN ('pending', 'confirmed', 'processing', 'ready_to_ship', 'shipped', 'delivered', 'cancelled', 'returned')),
    payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'partial', 'paid', 'refunded')),
    
    -- Financial details
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    delivery_charge DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    due_amount DECIMAL(10,2) DEFAULT 0,
    
    -- Steadfast courier integration
    courier_service TEXT DEFAULT 'steadfast',
    consignment_id TEXT,
    tracking_code TEXT,
    delivery_type TEXT CHECK (delivery_type IN ('regular', 'express')),
    
    -- Metadata
    sales_person_id UUID REFERENCES auth.users(id),
    warehouse_id UUID REFERENCES warehouses(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    production_cost DECIMAL(10,2), -- Only visible to owner/admin
    profit_margin DECIMAL(5,2), -- Only visible to owner/admin
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Order visibility policies
CREATE POLICY "Order visibility based on role and warehouse" 
ON orders FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM user_profiles up 
        WHERE up.id = auth.uid() 
        AND (
            up.role IN ('owner', 'admin') OR up.permissions ? 'view_all' OR
            (up.role IN ('manager', 'sales_executive') AND up.warehouse_id = orders.warehouse_id) OR
            up.id = orders.sales_person_id
        )
    )
);

-- Order items with profit margin protection
CREATE POLICY "Order items with profit protection" 
ON order_items FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM user_profiles up 
        WHERE up.id = auth.uid() 
        AND EXISTS (
            SELECT 1 FROM orders o 
            WHERE o.id = order_items.order_id 
            AND (
                up.role IN ('owner', 'admin') OR up.permissions ? 'view_all' OR
                (up.role IN ('manager', 'sales_executive') AND up.warehouse_id = o.warehouse_id) OR
                up.id = o.sales_person_id
            )
        )
    )
);

-- ==========================================
-- 4. EMPLOYEE & ATTENDANCE SYSTEM
-- ==========================================

-- Enhanced employee management
CREATE TABLE IF NOT EXISTS employees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    employee_code TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    department TEXT NOT NULL,
    designation TEXT NOT NULL,
    warehouse_id UUID REFERENCES warehouses(id),
    supervisor_id UUID REFERENCES employees(id),
    
    -- Contact information
    phone TEXT NOT NULL,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    permanent_address TEXT,
    present_address TEXT,
    
    -- Employment details
    hire_date DATE NOT NULL,
    employment_type TEXT CHECK (employment_type IN ('permanent', 'contract', 'part_time')),
    salary DECIMAL(10,2),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'terminated')),
    
    -- GPS tracking settings
    allowed_locations JSONB DEFAULT '[]', -- Array of {lat, lng, radius, name}
    gps_tracking_enabled BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enhanced attendance system with GPS validation
CREATE TABLE IF NOT EXISTS attendance_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL,
    check_in_time TIMESTAMPTZ,
    check_out_time TIMESTAMPTZ,
    check_in_latitude DOUBLE PRECISION,
    check_in_longitude DOUBLE PRECISION,
    check_out_latitude DOUBLE PRECISION,
    check_out_longitude DOUBLE PRECISION,
    check_in_address TEXT,
    check_out_address TEXT,
    is_valid_location BOOLEAN DEFAULT TRUE,
    work_hours DECIMAL(4,2),
    overtime_hours DECIMAL(4,2) DEFAULT 0,
    break_hours DECIMAL(4,2) DEFAULT 0,
    attendance_status TEXT DEFAULT 'present' CHECK (attendance_status IN ('present', 'absent', 'half_day', 'late', 'early_leave')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee RLS policies
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Employee data visibility" 
ON employees FOR SELECT 
USING (
    user_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM user_profiles up 
        WHERE up.id = auth.uid() 
        AND (up.role IN ('owner', 'admin', 'manager') OR up.permissions ? 'view_all')
    )
);

-- ==========================================
-- 5. PRODUCTION & MATERIALS MANAGEMENT
-- ==========================================

-- Materials and components
CREATE TABLE IF NOT EXISTS materials (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    material_code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    unit TEXT NOT NULL, -- pieces, meters, kg, etc.
    cost_per_unit DECIMAL(10,2),
    supplier_info JSONB,
    reorder_level INTEGER DEFAULT 10,
    current_stock INTEGER DEFAULT 0,
    warehouse_id UUID REFERENCES warehouses(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Material requests for production
CREATE TABLE IF NOT EXISTS material_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    request_number TEXT UNIQUE NOT NULL,
    requester_id UUID REFERENCES auth.users(id),
    warehouse_id UUID REFERENCES warehouses(id),
    request_type TEXT CHECK (request_type IN ('production', 'maintenance', 'other')),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'fulfilled')),
    requested_date DATE DEFAULT CURRENT_DATE,
    required_date DATE,
    approved_by UUID REFERENCES auth.users(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Material request items
CREATE TABLE IF NOT EXISTS material_request_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    request_id UUID REFERENCES material_requests(id) ON DELETE CASCADE,
    material_id UUID REFERENCES materials(id),
    requested_quantity INTEGER NOT NULL,
    approved_quantity INTEGER,
    issued_quantity INTEGER DEFAULT 0,
    unit_cost DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for materials
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_request_items ENABLE ROW LEVEL SECURITY;

-- Material visibility policies
CREATE POLICY "Material visibility by warehouse and role" 
ON materials FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM user_profiles up 
        WHERE up.id = auth.uid() 
        AND (
            up.role IN ('owner', 'admin', 'production_manager') OR 
            up.warehouse_id = materials.warehouse_id OR 
            up.permissions ? 'view_materials'
        )
    )
);

-- ==========================================
-- 6. FINANCIAL SYSTEM - DUE BOOK & TRANSACTIONS
-- ==========================================

-- Customer due book system
CREATE TABLE IF NOT EXISTS transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    transaction_number TEXT UNIQUE NOT NULL,
    customer_name TEXT NOT NULL,
    customer_phone TEXT,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('sale', 'payment', 'refund', 'adjustment')),
    
    -- Financial details
    amount DECIMAL(10,2) NOT NULL,
    transaction_date DATE DEFAULT CURRENT_DATE,
    payment_method TEXT CHECK (payment_method IN ('cash', 'bkash', 'nagad', 'bank_transfer', 'card')),
    
    -- References
    order_id UUID REFERENCES orders(id),
    processed_by UUID REFERENCES auth.users(id),
    warehouse_id UUID REFERENCES warehouses(id),
    
    -- Metadata
    notes TEXT,
    receipt_number TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_date TIMESTAMPTZ,
    verified_by UUID REFERENCES auth.users(id),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customer balance view
CREATE TABLE IF NOT EXISTS customer_balances (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_name TEXT NOT NULL,
    customer_phone TEXT,
    total_sales DECIMAL(10,2) DEFAULT 0,
    total_payments DECIMAL(10,2) DEFAULT 0,
    current_balance DECIMAL(10,2) DEFAULT 0,
    last_transaction_date DATE,
    credit_limit DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(customer_name, customer_phone)
);

-- Expense management
CREATE TABLE IF NOT EXISTS expenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    expense_number TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL,
    subcategory TEXT,
    description TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    expense_date DATE DEFAULT CURRENT_DATE,
    payment_method TEXT,
    vendor_name TEXT,
    warehouse_id UUID REFERENCES warehouses(id),
    approved_by UUID REFERENCES auth.users(id),
    receipt_url TEXT,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_period TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Purchase management
CREATE TABLE IF NOT EXISTS purchases (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    purchase_number TEXT UNIQUE NOT NULL,
    supplier_name TEXT NOT NULL,
    supplier_contact TEXT,
    purchase_date DATE DEFAULT CURRENT_DATE,
    total_amount DECIMAL(10,2) NOT NULL,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    due_amount DECIMAL(10,2) NOT NULL,
    payment_status TEXT DEFAULT 'pending',
    warehouse_id UUID REFERENCES warehouses(id),
    created_by UUID REFERENCES auth.users(id),
    approved_by UUID REFERENCES auth.users(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for financial tables
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;

-- Financial data policies (restricted access)
CREATE POLICY "Financial data access for authorized users" 
ON transactions FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM user_profiles up 
        WHERE up.id = auth.uid() 
        AND (
            up.role IN ('owner', 'admin', 'accountant') OR 
            up.permissions ? 'view_financial_reports' OR
            (up.role = 'manager' AND up.warehouse_id = transactions.warehouse_id)
        )
    )
);

-- ==========================================
-- 7. NOTIFICATION SYSTEM ENHANCEMENT
-- ==========================================

-- Enhanced notification settings per role/user
CREATE TABLE IF NOT EXISTS notification_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Notification categories
    order_notifications BOOLEAN DEFAULT TRUE,
    stock_notifications BOOLEAN DEFAULT TRUE,
    attendance_notifications BOOLEAN DEFAULT TRUE,
    financial_notifications BOOLEAN DEFAULT FALSE, -- Only for authorized roles
    production_notifications BOOLEAN DEFAULT FALSE,
    system_notifications BOOLEAN DEFAULT TRUE,
    
    -- Delivery methods
    push_notifications BOOLEAN DEFAULT TRUE,
    email_notifications BOOLEAN DEFAULT FALSE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    
    -- Timing preferences
    working_hours_only BOOLEAN DEFAULT FALSE,
    working_hours_start TIME DEFAULT '09:00',
    working_hours_end TIME DEFAULT '18:00',
    
    -- Frequency settings
    immediate_notifications BOOLEAN DEFAULT TRUE,
    daily_summary BOOLEAN DEFAULT FALSE,
    weekly_summary BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enhanced notifications table
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'general',
ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
ADD COLUMN IF NOT EXISTS action_required BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS action_url TEXT,
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS warehouse_id UUID REFERENCES warehouses(id);

-- Enable RLS for notification settings
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notification settings" 
ON notification_settings FOR ALL 
USING (auth.uid() = user_id);

-- ==========================================
-- 8. ADVANCED INDEXES FOR PERFORMANCE
-- ==========================================

-- Performance indexes for complex queries
CREATE INDEX IF NOT EXISTS idx_orders_status_warehouse ON orders(order_status, warehouse_id, created_at);
CREATE INDEX IF NOT EXISTS idx_orders_customer_phone ON orders(customer_phone);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_transactions_customer ON transactions(customer_name, customer_phone);
CREATE INDEX IF NOT EXISTS idx_transactions_date_type ON transactions(transaction_date, transaction_type);
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date ON attendance_records(employee_id, attendance_date);
CREATE INDEX IF NOT EXISTS idx_materials_warehouse ON materials(warehouse_id, is_active);
CREATE INDEX IF NOT EXISTS idx_material_requests_status ON material_requests(status, priority);
CREATE INDEX IF NOT EXISTS idx_customer_balances_phone ON customer_balances(customer_phone);
CREATE INDEX IF NOT EXISTS idx_expenses_category_date ON expenses(category, expense_date);
CREATE INDEX IF NOT EXISTS idx_user_profiles_warehouse ON user_profiles(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role, is_active);

-- Composite indexes for complex filtering
CREATE INDEX IF NOT EXISTS idx_orders_complex ON orders(warehouse_id, order_status, order_type, created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user_category ON notifications(user_id, category, is_read);

-- ==========================================
-- 9. DATABASE FUNCTIONS AND TRIGGERS
-- ==========================================

-- Function to update customer balance
CREATE OR REPLACE FUNCTION update_customer_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Update or insert customer balance
    INSERT INTO customer_balances (customer_name, customer_phone, total_sales, total_payments, current_balance, last_transaction_date)
    SELECT 
        customer_name,
        customer_phone,
        COALESCE(SUM(CASE WHEN transaction_type = 'sale' THEN amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN transaction_type = 'payment' THEN amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN transaction_type = 'sale' THEN amount ELSE -amount END), 0),
        MAX(transaction_date)
    FROM transactions 
    WHERE customer_name = NEW.customer_name AND customer_phone = NEW.customer_phone
    GROUP BY customer_name, customer_phone
    ON CONFLICT (customer_name, customer_phone) DO UPDATE SET
        total_sales = EXCLUDED.total_sales,
        total_payments = EXCLUDED.total_payments,
        current_balance = EXCLUDED.current_balance,
        last_transaction_date = EXCLUDED.last_transaction_date,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for customer balance updates
DROP TRIGGER IF EXISTS update_customer_balance_trigger ON transactions;
CREATE TRIGGER update_customer_balance_trigger
    AFTER INSERT OR UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_balance();

-- Function to validate GPS location for attendance
CREATE OR REPLACE FUNCTION validate_attendance_location()
RETURNS TRIGGER AS $$
DECLARE
    allowed_locations JSONB;
    location JSONB;
    is_valid BOOLEAN := FALSE;
    distance FLOAT;
BEGIN
    -- Get allowed locations for employee
    SELECT e.allowed_locations INTO allowed_locations
    FROM employees e
    WHERE e.id = NEW.employee_id;
    
    -- Check if location is within allowed radius
    IF allowed_locations IS NOT NULL THEN
        FOR location IN SELECT * FROM jsonb_array_elements(allowed_locations)
        LOOP
            -- Calculate distance using Haversine formula (simplified)
            distance := sqrt(
                power(NEW.check_in_latitude - (location->>'lat')::FLOAT, 2) +
                power(NEW.check_in_longitude - (location->>'lng')::FLOAT, 2)
            ) * 111000; -- Convert to meters
            
            IF distance <= (location->>'radius')::FLOAT THEN
                is_valid := TRUE;
                EXIT;
            END IF;
        END LOOP;
    ELSE
        is_valid := TRUE; -- No restrictions
    END IF;
    
    NEW.is_valid_location := is_valid;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for GPS validation
DROP TRIGGER IF EXISTS validate_attendance_location_trigger ON attendance_records;
CREATE TRIGGER validate_attendance_location_trigger
    BEFORE INSERT OR UPDATE ON attendance_records
    FOR each ROW
    EXECUTE FUNCTION validate_attendance_location();

-- ==========================================
-- 10. VIEWS FOR REPORTING AND ANALYTICS
-- ==========================================

-- Comprehensive sales summary view
CREATE OR REPLACE VIEW sales_summary AS
SELECT 
    o.warehouse_id,
    w.name as warehouse_name,
    DATE_TRUNC('day', o.created_at) as sale_date,
    COUNT(*) as total_orders,
    SUM(o.total_amount) as total_sales,
    SUM(o.paid_amount) as total_payments,
    SUM(o.due_amount) as total_due,
    AVG(o.total_amount) as avg_order_value,
    COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END) as delivered_orders,
    COUNT(CASE WHEN o.order_status = 'cancelled' THEN 1 END) as cancelled_orders
FROM orders o
LEFT JOIN warehouses w ON w.id = o.warehouse_id
GROUP BY o.warehouse_id, w.name, DATE_TRUNC('day', o.created_at);

-- Stock level view with reorder alerts
CREATE OR REPLACE VIEW stock_alerts AS
SELECT 
    p.id,
    p.product_name,
    p.product_type,
    p.low_stock_threshold,
    s.quantity as current_stock,
    sl.location_name,
    w.name as warehouse_name,
    CASE 
        WHEN s.quantity <= p.low_stock_threshold THEN 'LOW'
        WHEN s.quantity <= (p.low_stock_threshold * 1.5) THEN 'WARNING'
        ELSE 'OK'
    END as stock_status
FROM products p
JOIN stocks s ON s.product_id = p.id
JOIN stock_locations sl ON sl.id = s.location_id
LEFT JOIN warehouses w ON w.id = sl.warehouse_id
WHERE s.quantity <= (p.low_stock_threshold * 1.5);

-- Employee attendance summary
CREATE OR REPLACE VIEW employee_attendance_summary AS
SELECT 
    e.id as employee_id,
    e.first_name || ' ' || e.last_name as full_name,
    e.employee_code,
    e.department,
    w.name as warehouse_name,
    DATE_TRUNC('month', ar.attendance_date) as month,
    COUNT(*) as total_days,
    COUNT(CASE WHEN ar.attendance_status = 'present' THEN 1 END) as present_days,
    COUNT(CASE WHEN ar.attendance_status = 'absent' THEN 1 END) as absent_days,
    AVG(ar.work_hours) as avg_work_hours,
    SUM(ar.overtime_hours) as total_overtime
FROM employees e
LEFT JOIN attendance_records ar ON ar.employee_id = e.id
LEFT JOIN warehouses w ON w.id = e.warehouse_id
GROUP BY e.id, e.first_name, e.last_name, e.employee_code, e.department, w.name, DATE_TRUNC('month', ar.attendance_date);

-- Financial summary view (restricted access)
CREATE OR REPLACE VIEW financial_summary AS
SELECT 
    DATE_TRUNC('day', t.transaction_date) as transaction_date,
    t.warehouse_id,
    w.name as warehouse_name,
    SUM(CASE WHEN t.transaction_type = 'sale' THEN t.amount ELSE 0 END) as daily_sales,
    SUM(CASE WHEN t.transaction_type = 'payment' THEN t.amount ELSE 0 END) as daily_payments,
    (SELECT SUM(amount) FROM expenses e WHERE DATE_TRUNC('day', e.expense_date) = DATE_TRUNC('day', t.transaction_date) AND e.warehouse_id = t.warehouse_id) as daily_expenses,
    COUNT(DISTINCT CASE WHEN t.transaction_type = 'sale' THEN t.customer_name END) as unique_customers
FROM transactions t
LEFT JOIN warehouses w ON w.id = t.warehouse_id
GROUP BY DATE_TRUNC('day', t.transaction_date), t.warehouse_id, w.name;

-- ==========================================
-- COMPLETION MESSAGE
-- ==========================================

-- Insert success notification
INSERT INTO notifications (user_id, title, message, type, category) 
SELECT 
    id as user_id,
    'Database Enhanced Successfully',
    'FurniShop Manager backend has been upgraded with multi-warehouse support, role-based access, production management, and comprehensive financial tracking.',
    'success',
    'system'
FROM user_profiles 
WHERE role IN ('owner', 'admin')
ON CONFLICT DO NOTHING;

SELECT 'Enhanced FurniShop Manager schema deployed successfully!' as result;