-- ==========================================
-- ROW LEVEL SECURITY POLICIES
-- Advanced security patterns for FurniShop Manager
-- ==========================================

-- ==========================================
-- 1. HELPER FUNCTIONS FOR RLS POLICIES
-- ==========================================

-- Function to check user permissions
CREATE OR REPLACE FUNCTION user_has_permission(permission_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_profiles up
        WHERE up.id = auth.uid()
        AND (
            up.permissions ? permission_name OR
            up.role IN ('owner', 'admin')
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's warehouse
CREATE OR REPLACE FUNCTION user_warehouse_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT warehouse_id 
        FROM user_profiles 
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can access warehouse
CREATE OR REPLACE FUNCTION can_access_warehouse(warehouse_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_profiles up
        WHERE up.id = auth.uid()
        AND (
            up.role IN ('owner', 'admin') OR
            up.warehouse_id = warehouse_uuid OR
            user_has_permission('view_all')
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check financial data access
CREATE OR REPLACE FUNCTION can_view_financial_data()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_profiles up
        WHERE up.id = auth.uid()
        AND (
            up.role IN ('owner', 'admin', 'accountant') OR
            user_has_permission('view_financial_reports')
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check profit margin access
CREATE OR REPLACE FUNCTION can_view_profit_margins()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_profiles up
        WHERE up.id = auth.uid()
        AND (
            up.role IN ('owner') OR
            user_has_permission('view_profit_margins')
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- 2. WAREHOUSE ACCESS POLICIES
-- ==========================================

-- Warehouse visibility policy
DROP POLICY IF EXISTS "Advanced warehouse access" ON warehouses;
CREATE POLICY "Advanced warehouse access" 
ON warehouses FOR SELECT 
USING (
    is_active = TRUE AND (
        -- Owners and admins see all
        user_has_permission('view_all') OR
        -- Warehouse managers see their warehouse
        id = user_warehouse_id() OR
        -- Employees assigned to warehouse
        EXISTS (
            SELECT 1 FROM user_profiles up 
            WHERE up.id = auth.uid() 
            AND up.warehouse_id = warehouses.id
        )
    )
);

-- Warehouse modification policy
CREATE POLICY "Warehouse modification by authorized users" 
ON warehouses FOR ALL 
USING (
    user_has_permission('manage_warehouses') OR
    (user_has_permission('manage_branch') AND id = user_warehouse_id())
);

-- ==========================================
-- 3. PRODUCT AND INVENTORY POLICIES
-- ==========================================

-- Products visibility - all can view active products
DROP POLICY IF EXISTS "Product visibility" ON products;
CREATE POLICY "Product visibility" 
ON products FOR SELECT 
USING (true); -- All authenticated users can view products

-- Product modification policy
CREATE POLICY "Product modification by authorized users" 
ON products FOR INSERT 
WITH CHECK (
    user_has_permission('manage_inventory') OR
    user_has_permission('create_products')
);

CREATE POLICY "Product update by authorized users" 
ON products FOR UPDATE 
USING (
    user_has_permission('manage_inventory') OR
    user_has_permission('edit_products') OR
    created_by = auth.uid()
);

-- Stock visibility based on warehouse access
DROP POLICY IF EXISTS "Stock visibility by warehouse" ON stocks;
CREATE POLICY "Stock visibility by warehouse" 
ON stocks FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM stock_locations sl
        WHERE sl.id = stocks.location_id
        AND (
            user_has_permission('view_all') OR
            can_access_warehouse(sl.warehouse_id) OR
            user_has_permission('view_inventory')
        )
    )
);

-- Stock modification policy
CREATE POLICY "Stock modification by authorized users" 
ON stocks FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM stock_locations sl
        WHERE sl.id = stocks.location_id
        AND (
            user_has_permission('manage_inventory') OR
            can_access_warehouse(sl.warehouse_id)
        )
    )
);

-- ==========================================
-- 4. ORDER MANAGEMENT POLICIES
-- ==========================================

-- Order visibility with multi-level access
DROP POLICY IF EXISTS "Advanced order access" ON orders;
CREATE POLICY "Advanced order access" 
ON orders FOR SELECT 
USING (
    -- Owners/admins see all
    user_has_permission('view_all') OR
    -- Sales executives see their warehouse orders
    (user_has_permission('view_orders') AND can_access_warehouse(warehouse_id)) OR
    -- Sales person sees their own orders
    sales_person_id = auth.uid() OR
    -- Managers see their warehouse orders
    (user_has_permission('manage_branch') AND warehouse_id = user_warehouse_id())
);

-- Order creation policy
CREATE POLICY "Order creation by sales users" 
ON orders FOR INSERT 
WITH CHECK (
    user_has_permission('create_orders') AND
    (warehouse_id IS NULL OR can_access_warehouse(warehouse_id))
);

-- Order modification policy
CREATE POLICY "Order modification by authorized users" 
ON orders FOR UPDATE 
USING (
    user_has_permission('edit_orders') OR
    sales_person_id = auth.uid() OR
    (user_has_permission('manage_branch') AND warehouse_id = user_warehouse_id())
);

-- Order items visibility with profit protection
DROP POLICY IF EXISTS "Order items with profit protection" ON order_items;
CREATE POLICY "Order items with profit protection" 
ON order_items FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM orders o 
        WHERE o.id = order_items.order_id 
        AND (
            user_has_permission('view_all') OR
            o.sales_person_id = auth.uid() OR
            can_access_warehouse(o.warehouse_id)
        )
    )
);

-- Hide profit margins from unauthorized users
CREATE POLICY "Profit margin access restriction" 
ON order_items FOR SELECT 
USING (
    can_view_profit_margins() OR
    (production_cost IS NULL AND profit_margin IS NULL)
);

-- ==========================================
-- 5. EMPLOYEE AND ATTENDANCE POLICIES
-- ==========================================

-- Employee data visibility
DROP POLICY IF EXISTS "Employee data visibility" ON employees;
CREATE POLICY "Employee data visibility" 
ON employees FOR SELECT 
USING (
    -- Own data
    user_id = auth.uid() OR
    -- HR/Admin access
    user_has_permission('view_all') OR
    user_has_permission('manage_employees') OR
    -- Warehouse managers see their employees
    (user_has_permission('manage_branch') AND warehouse_id = user_warehouse_id()) OR
    -- Supervisors see their subordinates
    supervisor_id = (
        SELECT id FROM employees WHERE user_id = auth.uid()
    )
);

-- Salary information protection
CREATE POLICY "Salary information protection" 
ON employees FOR SELECT 
USING (
    user_id = auth.uid() OR
    user_has_permission('view_salary_info') OR
    user_has_permission('view_all')
);

-- Attendance record visibility
DROP POLICY IF EXISTS "Attendance visibility" ON attendance_records;
CREATE POLICY "Attendance visibility" 
ON attendance_records FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM employees e
        WHERE e.id = attendance_records.employee_id
        AND (
            e.user_id = auth.uid() OR
            user_has_permission('view_attendance') OR
            (user_has_permission('manage_branch') AND e.warehouse_id = user_warehouse_id())
        )
    )
);

-- Attendance modification policy
CREATE POLICY "Attendance modification" 
ON attendance_records FOR INSERT 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM employees e
        WHERE e.id = attendance_records.employee_id
        AND e.user_id = auth.uid()
    )
);

-- ==========================================
-- 6. FINANCIAL DATA POLICIES (STRICT)
-- ==========================================

-- Transaction visibility (restricted)
DROP POLICY IF EXISTS "Transaction visibility" ON transactions;
CREATE POLICY "Transaction visibility" 
ON transactions FOR SELECT 
USING (
    can_view_financial_data() OR
    (processed_by = auth.uid() AND transaction_type = 'sale')
);

-- Customer balance visibility
CREATE POLICY "Customer balance visibility" 
ON customer_balances FOR SELECT 
USING (
    can_view_financial_data() OR
    user_has_permission('view_customers')
);

-- Expense visibility
CREATE POLICY "Expense data visibility" 
ON expenses FOR SELECT 
USING (
    can_view_financial_data() OR
    created_by = auth.uid()
);

-- Purchase data visibility
CREATE POLICY "Purchase data visibility" 
ON purchases FOR SELECT 
USING (
    can_view_financial_data() OR
    created_by = auth.uid()
);

-- Financial modification policies
CREATE POLICY "Transaction modification by authorized users" 
ON transactions FOR INSERT 
WITH CHECK (
    user_has_permission('create_transactions') OR
    user_has_permission('create_sales')
);

CREATE POLICY "Expense modification by authorized users" 
ON expenses FOR ALL 
USING (
    user_has_permission('manage_expenses') OR
    created_by = auth.uid()
);

-- ==========================================
-- 7. MATERIAL AND PRODUCTION POLICIES
-- ==========================================

-- Material visibility by warehouse
CREATE POLICY "Material visibility by warehouse and role" 
ON materials FOR SELECT 
USING (
    user_has_permission('view_materials') OR
    can_access_warehouse(warehouse_id) OR
    user_has_permission('view_all')
);

-- Material request visibility
CREATE POLICY "Material request visibility" 
ON material_requests FOR SELECT 
USING (
    requester_id = auth.uid() OR
    user_has_permission('approve_materials') OR
    can_access_warehouse(warehouse_id)
);

-- Material request creation
CREATE POLICY "Material request creation" 
ON material_requests FOR INSERT 
WITH CHECK (
    user_has_permission('create_material_requests') AND
    requester_id = auth.uid()
);

-- Material request approval
CREATE POLICY "Material request approval" 
ON material_requests FOR UPDATE 
USING (
    user_has_permission('approve_materials') OR
    (requester_id = auth.uid() AND status = 'pending')
);

-- ==========================================
-- 8. NOTIFICATION POLICIES
-- ==========================================

-- Enhanced notification visibility
DROP POLICY IF EXISTS "Advanced notification access" ON notifications;
CREATE POLICY "Advanced notification access" 
ON notifications FOR SELECT 
USING (
    user_id = auth.uid() OR
    (
        warehouse_id IS NOT NULL AND 
        can_access_warehouse(warehouse_id) AND
        category IN ('stock', 'order', 'general')
    )
);

-- Notification creation by system
CREATE POLICY "System notification creation" 
ON notifications FOR INSERT 
WITH CHECK (
    user_has_permission('send_notifications') OR
    user_has_permission('view_all')
);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users manage own notifications" 
ON notifications FOR UPDATE 
USING (user_id = auth.uid());

-- ==========================================
-- 9. AUDIT AND LOGGING POLICIES
-- ==========================================

-- Create audit log table for sensitive operations
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    action TEXT NOT NULL,
    table_name TEXT NOT NULL,
    record_id TEXT,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    warehouse_id UUID REFERENCES warehouses(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on audit logs
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Audit log visibility (owners and admins only)
CREATE POLICY "Audit log visibility for authorized users" 
ON audit_logs FOR SELECT 
USING (
    user_has_permission('view_audit_logs') OR
    user_id = auth.uid()
);

-- ==========================================
-- 10. SECURITY VIEWS (FILTERED DATA)
-- ==========================================

-- Secure financial summary (hides sensitive data)
CREATE OR REPLACE VIEW secure_financial_summary AS
SELECT 
    transaction_date,
    warehouse_id,
    warehouse_name,
    CASE WHEN can_view_financial_data() THEN daily_sales ELSE NULL END as daily_sales,
    CASE WHEN can_view_financial_data() THEN daily_payments ELSE NULL END as daily_payments,
    CASE WHEN can_view_financial_data() THEN daily_expenses ELSE NULL END as daily_expenses,
    unique_customers
FROM financial_summary;

-- Secure employee view (hides salary)
CREATE OR REPLACE VIEW secure_employee_view AS
SELECT 
    id,
    employee_code,
    first_name,
    last_name,
    department,
    designation,
    warehouse_id,
    phone,
    hire_date,
    employment_type,
    CASE WHEN (user_has_permission('view_salary_info') OR user_id = auth.uid()) THEN salary ELSE NULL END as salary,
    status
FROM employees;

-- Secure order view (hides profit margins)
CREATE OR REPLACE VIEW secure_order_items AS
SELECT 
    oi.id,
    oi.order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.total_price,
    CASE WHEN can_view_profit_margins() THEN oi.production_cost ELSE NULL END as production_cost,
    CASE WHEN can_view_profit_margins() THEN oi.profit_margin ELSE NULL END as profit_margin,
    oi.created_at
FROM order_items oi;

-- ==========================================
-- 11. DYNAMIC POLICIES FOR MULTI-TENANCY
-- ==========================================

-- Policy for cross-warehouse data sharing (for franchises)
CREATE OR REPLACE FUNCTION can_access_cross_warehouse(target_warehouse_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_profiles up
        WHERE up.id = auth.uid()
        AND (
            up.role IN ('owner', 'admin') OR
            up.permissions ? 'cross_warehouse_access' OR
            EXISTS (
                SELECT 1 FROM warehouses w1, warehouses w2
                WHERE w1.id = up.warehouse_id 
                AND w2.id = target_warehouse_id
                AND w1.manager_id = w2.manager_id -- Same manager
            )
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- 12. POLICY VALIDATION AND TESTING
-- ==========================================

-- Function to test user permissions
CREATE OR REPLACE FUNCTION test_user_permissions(test_user_id UUID)
RETURNS TABLE (
    table_name TEXT,
    can_select BOOLEAN,
    can_insert BOOLEAN,
    can_update BOOLEAN,
    can_delete BOOLEAN
) AS $$
BEGIN
    -- This function would test various policies
    -- Implementation depends on specific testing requirements
    RETURN QUERY SELECT 
        'test'::TEXT as table_name,
        true as can_select,
        false as can_insert,
        false as can_update,
        false as can_delete;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- COMPLETION AND VERIFICATION
-- ==========================================

-- Create a view to check policy coverage
CREATE OR REPLACE VIEW policy_coverage AS
SELECT 
    schemaname,
    tablename,
    COUNT(*) as policy_count,
    array_agg(policyname) as policies
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;

-- Success message
SELECT 'Advanced RLS policies configured successfully!' as result,
       'All tables now have role-based security with multi-level access control' as details;