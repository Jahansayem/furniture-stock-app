-- ==========================================
-- ENHANCED FURNITURE STOCK APP - SUPABASE SQL
-- Copy these queries one by one into Supabase SQL Editor
-- ==========================================

-- 1. CREATE USER PROFILES TABLE (if it doesn't exist)
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    profile_picture_url TEXT,
    role TEXT NOT NULL DEFAULT 'staff',
    is_checked_in BOOLEAN DEFAULT FALSE,
    last_checked_in_at TIMESTAMPTZ,
    last_checked_out_at TIMESTAMPTZ,
    last_known_latitude DOUBLE PRECISION,
    last_known_longitude DOUBLE PRECISION,
    last_known_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for user_profiles (drop existing ones first)
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
CREATE POLICY "Users can view own profile" 
ON user_profiles FOR SELECT 
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
CREATE POLICY "Users can insert own profile" 
ON user_profiles FOR INSERT 
WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
CREATE POLICY "Users can update own profile" 
ON user_profiles FOR UPDATE 
USING (auth.uid() = id);

-- 1b. ADD NEW COLUMNS TO EXISTING USER PROFILES (if table already exists)
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT,
ADD COLUMN IF NOT EXISTS is_checked_in BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS last_checked_in_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_checked_out_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_known_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS last_known_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS last_known_address TEXT;

-- 2. CREATE INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_user_profiles_location 
ON user_profiles(last_known_latitude, last_known_longitude);

CREATE INDEX IF NOT EXISTS idx_user_profiles_check_in 
ON user_profiles(is_checked_in);

-- 3. CREATE PROFILE PICTURES STORAGE BUCKET
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-pictures', 'profile-pictures', true)
ON CONFLICT (id) DO NOTHING;

-- 4. STORAGE POLICIES FOR PROFILE PICTURES
DROP POLICY IF EXISTS "Users can upload their own profile pictures" ON storage.objects;
CREATE POLICY "Users can upload their own profile pictures" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'profile-pictures' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Profile pictures are publicly viewable" ON storage.objects;
CREATE POLICY "Profile pictures are publicly viewable" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'profile-pictures');

DROP POLICY IF EXISTS "Users can update their own profile pictures" ON storage.objects;
CREATE POLICY "Users can update their own profile pictures" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'profile-pictures' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can delete their own profile pictures" ON storage.objects;
CREATE POLICY "Users can delete their own profile pictures" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'profile-pictures' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 5. CREATE ATTENDANCE LOG TABLE
CREATE TABLE IF NOT EXISTS attendance_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL CHECK (action_type IN ('check_in', 'check_out')),
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    address TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. ENABLE RLS ON ATTENDANCE LOG
ALTER TABLE attendance_log ENABLE ROW LEVEL SECURITY;

-- 7. ATTENDANCE LOG POLICIES
DROP POLICY IF EXISTS "Users can view own attendance" ON attendance_log;
CREATE POLICY "Users can view own attendance" 
ON attendance_log FOR SELECT 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own attendance" ON attendance_log;
CREATE POLICY "Users can insert own attendance" 
ON attendance_log FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 8. ATTENDANCE LOG INDEXES
CREATE INDEX IF NOT EXISTS idx_attendance_log_user_id ON attendance_log(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_log_timestamp ON attendance_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_attendance_log_action_type ON attendance_log(action_type);

-- 9. CREATE SALES TABLE (if it doesn't exist)
CREATE TABLE IF NOT EXISTS sales (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    sale_type TEXT NOT NULL CHECK (sale_type IN ('online_cod', 'offline')),
    customer_name TEXT,
    customer_phone TEXT,
    customer_address TEXT,
    payment_status TEXT DEFAULT 'pending',
    notes TEXT,
    sale_latitude DOUBLE PRECISION,
    sale_longitude DOUBLE PRECISION,
    sale_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on sales
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

-- Sales policies
DROP POLICY IF EXISTS "Users can view all sales" ON sales;
CREATE POLICY "Users can view all sales" 
ON sales FOR SELECT 
USING (true);

DROP POLICY IF EXISTS "Users can insert sales" ON sales;
CREATE POLICY "Users can insert sales" 
ON sales FOR INSERT 
WITH CHECK (true);

-- 9b. ADD LOCATION TO EXISTING SALES TABLE
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS sale_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS sale_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS sale_address TEXT;

CREATE INDEX IF NOT EXISTS idx_sales_location 
ON sales(sale_latitude, sale_longitude);

-- 10. CREATE PRODUCTS TABLE (if it doesn't exist)
CREATE TABLE IF NOT EXISTS products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_name TEXT NOT NULL,
    product_type TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    image_url TEXT,
    description TEXT,
    low_stock_threshold INTEGER NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Enable RLS on products
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Products policies
DROP POLICY IF EXISTS "Users can view all products" ON products;
CREATE POLICY "Users can view all products" 
ON products FOR SELECT 
USING (true);

DROP POLICY IF EXISTS "Users can insert products" ON products;
CREATE POLICY "Users can insert products" 
ON products FOR INSERT 
WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Users can update products" ON products;
CREATE POLICY "Users can update products" 
ON products FOR UPDATE 
USING (true);

-- Add price column to existing products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS price DECIMAL(10,2) NOT NULL DEFAULT 0;

-- 11. CREATE STOCK LOCATIONS TABLE (if it doesn't exist)
CREATE TABLE IF NOT EXISTS stock_locations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    location_name TEXT NOT NULL,
    location_type TEXT NOT NULL,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on stock_locations
ALTER TABLE stock_locations ENABLE ROW LEVEL SECURITY;

-- Stock locations policies
DROP POLICY IF EXISTS "Users can view all stock locations" ON stock_locations;
CREATE POLICY "Users can view all stock locations" 
ON stock_locations FOR SELECT 
USING (true);

-- Add address column to existing stock_locations table
ALTER TABLE stock_locations ADD COLUMN IF NOT EXISTS address TEXT;

-- 12. CREATE STOCKS TABLE (if it doesn't exist)
CREATE TABLE IF NOT EXISTS stocks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    location_id UUID REFERENCES stock_locations(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(product_id, location_id)
);

-- Enable RLS on stocks
ALTER TABLE stocks ENABLE ROW LEVEL SECURITY;

-- Stocks policies
DROP POLICY IF EXISTS "Users can view all stocks" ON stocks;
CREATE POLICY "Users can view all stocks" 
ON stocks FOR SELECT 
USING (true);

DROP POLICY IF EXISTS "Users can update stocks" ON stocks;
CREATE POLICY "Users can update stocks" 
ON stocks FOR UPDATE 
USING (true);

DROP POLICY IF EXISTS "Users can insert stocks" ON stocks;
CREATE POLICY "Users can insert stocks" 
ON stocks FOR INSERT 
WITH CHECK (true);

-- 13. CREATE NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('info', 'warning', 'error', 'success')),
    is_read BOOLEAN DEFAULT FALSE,
    data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

-- 14. ENABLE RLS ON NOTIFICATIONS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 15. NOTIFICATION POLICIES
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications" 
ON notifications FOR SELECT 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service can insert notifications" ON notifications;
CREATE POLICY "Service can insert notifications" 
ON notifications FOR INSERT 
WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications" 
ON notifications FOR UPDATE 
USING (auth.uid() = user_id);

-- 16. NOTIFICATION INDEXES
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- 17. CREATE ATTENDANCE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION log_attendance_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Check in
    IF OLD.is_checked_in = FALSE AND NEW.is_checked_in = TRUE THEN
        INSERT INTO attendance_log (
            user_id, action_type, timestamp, latitude, longitude, address
        ) VALUES (
            NEW.id, 'check_in', NEW.last_checked_in_at,
            NEW.last_known_latitude, NEW.last_known_longitude, NEW.last_known_address
        );
    END IF;
    
    -- Check out
    IF OLD.is_checked_in = TRUE AND NEW.is_checked_in = FALSE THEN
        INSERT INTO attendance_log (
            user_id, action_type, timestamp, latitude, longitude, address
        ) VALUES (
            NEW.id, 'check_out', NEW.last_checked_out_at,
            NEW.last_known_latitude, NEW.last_known_longitude, NEW.last_known_address
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 18. CREATE ATTENDANCE TRIGGER
DROP TRIGGER IF EXISTS attendance_log_trigger ON user_profiles;
CREATE TRIGGER attendance_log_trigger
    AFTER UPDATE ON user_profiles
    FOR EACH ROW
    WHEN (OLD.is_checked_in IS DISTINCT FROM NEW.is_checked_in)
    EXECUTE FUNCTION log_attendance_change();

-- 19. CREATE USER ACTIVITY VIEW
CREATE OR REPLACE VIEW user_activity_summary AS
SELECT 
    up.id,
    up.email,
    up.full_name,
    up.role,
    up.is_checked_in,
    up.last_checked_in_at,
    up.last_checked_out_at,
    up.last_known_address,
    (SELECT COUNT(*) 
     FROM attendance_log al 
     WHERE al.user_id = up.id 
     AND al.action_type = 'check_in' 
     AND al.timestamp >= date_trunc('month', NOW())) as monthly_check_ins,
    GREATEST(up.last_checked_in_at, up.last_checked_out_at) as last_activity
FROM user_profiles up;

-- 20. INSERT SAMPLE DATA (Optional)

-- Insert default stock locations
INSERT INTO stock_locations (location_name, location_type) VALUES
('Main Factory', 'factory'),
('Showroom 1', 'showroom')
ON CONFLICT DO NOTHING;

-- Insert welcome notifications for existing users
INSERT INTO notifications (user_id, title, message, type) 
SELECT 
    id as user_id,
    'Welcome to Enhanced App!',
    'New features: Profile pictures, check-in/out, and location tracking are now available.',
    'info'
FROM user_profiles 
ON CONFLICT DO NOTHING;

-- ==========================================
-- VERIFICATION QUERIES (Optional - for testing)
-- ==========================================

-- Check user profiles structure
-- SELECT * FROM user_profiles LIMIT 1;

-- Check attendance log
-- SELECT * FROM attendance_log ORDER BY timestamp DESC LIMIT 10;

-- Check notifications
-- SELECT * FROM notifications ORDER BY created_at DESC LIMIT 10;

-- Check user activity summary
-- SELECT * FROM user_activity_summary;
