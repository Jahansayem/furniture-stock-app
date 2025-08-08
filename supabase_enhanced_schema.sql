-- ==========================================
-- ENHANCED SUPABASE DATABASE SCHEMA
-- For Furniture Stock Management App
-- ==========================================

-- 1. Enhanced user_profiles table with location and check-in features
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT,
ADD COLUMN IF NOT EXISTS is_checked_in BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS last_checked_in_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_checked_out_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_known_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS last_known_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS last_known_address TEXT;

-- Create index for location-based queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_location 
ON user_profiles(last_known_latitude, last_known_longitude);

-- Create index for check-in status
CREATE INDEX IF NOT EXISTS idx_user_profiles_check_in 
ON user_profiles(is_checked_in);

-- 2. Create profile-pictures storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-pictures', 'profile-pictures', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Storage policy for profile pictures - allow authenticated users to upload
CREATE POLICY IF NOT EXISTS "Users can upload their own profile pictures" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'profile-pictures' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to view all profile pictures
CREATE POLICY IF NOT EXISTS "Profile pictures are publicly viewable" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'profile-pictures');

-- Allow users to update their own profile pictures
CREATE POLICY IF NOT EXISTS "Users can update their own profile pictures" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'profile-pictures' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to delete their own profile pictures
CREATE POLICY IF NOT EXISTS "Users can delete their own profile pictures" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'profile-pictures' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 4. Create attendance_log table to track check-in/out history
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

-- Enable RLS on attendance_log
ALTER TABLE attendance_log ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own attendance records
CREATE POLICY IF NOT EXISTS "Users can view own attendance" 
ON attendance_log FOR SELECT 
USING (auth.uid() = user_id);

-- Policy: Users can insert their own attendance records
CREATE POLICY IF NOT EXISTS "Users can insert own attendance" 
ON attendance_log FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Indexes for attendance_log
CREATE INDEX IF NOT EXISTS idx_attendance_log_user_id ON attendance_log(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_log_timestamp ON attendance_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_attendance_log_action_type ON attendance_log(action_type);

-- 5. Enhanced sales table (from previous session) with location tracking
-- Add location tracking to sales
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS sale_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS sale_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS sale_address TEXT;

-- Index for sales location
CREATE INDEX IF NOT EXISTS idx_sales_location 
ON sales(sale_latitude, sale_longitude);

-- 6. Create user_activity_summary view for dashboard analytics
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
    -- Calculate total check-ins this month
    (SELECT COUNT(*) 
     FROM attendance_log al 
     WHERE al.user_id = up.id 
     AND al.action_type = 'check_in' 
     AND al.timestamp >= date_trunc('month', NOW())) as monthly_check_ins,
    -- Calculate total working hours this month
    (SELECT COALESCE(SUM(
        CASE 
            WHEN al_out.timestamp IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (al_out.timestamp - al_in.timestamp))/3600
            ELSE 0
        END
    ), 0)
     FROM attendance_log al_in
     LEFT JOIN attendance_log al_out ON (
         al_out.user_id = al_in.user_id 
         AND al_out.action_type = 'check_out'
         AND al_out.timestamp > al_in.timestamp
         AND al_out.timestamp = (
             SELECT MIN(timestamp) 
             FROM attendance_log al_inner 
             WHERE al_inner.user_id = al_in.user_id 
             AND al_inner.action_type = 'check_out'
             AND al_inner.timestamp > al_in.timestamp
         )
     )
     WHERE al_in.user_id = up.id 
     AND al_in.action_type = 'check_in' 
     AND al_in.timestamp >= date_trunc('month', NOW())) as monthly_hours,
    -- Last activity timestamp
    GREATEST(up.last_checked_in_at, up.last_checked_out_at) as last_activity
FROM user_profiles up;

-- 7. Function to automatically log attendance when check-in/out status changes
CREATE OR REPLACE FUNCTION log_attendance_change()
RETURNS TRIGGER AS $$
BEGIN
    -- If is_checked_in changed from false to true (check in)
    IF OLD.is_checked_in = FALSE AND NEW.is_checked_in = TRUE THEN
        INSERT INTO attendance_log (
            user_id, 
            action_type, 
            timestamp, 
            latitude, 
            longitude, 
            address
        ) VALUES (
            NEW.id,
            'check_in',
            NEW.last_checked_in_at,
            NEW.last_known_latitude,
            NEW.last_known_longitude,
            NEW.last_known_address
        );
    END IF;
    
    -- If is_checked_in changed from true to false (check out)
    IF OLD.is_checked_in = TRUE AND NEW.is_checked_in = FALSE THEN
        INSERT INTO attendance_log (
            user_id, 
            action_type, 
            timestamp, 
            latitude, 
            longitude, 
            address
        ) VALUES (
            NEW.id,
            'check_out',
            NEW.last_checked_out_at,
            NEW.last_known_latitude,
            NEW.last_known_longitude,
            NEW.last_known_address
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for attendance logging
DROP TRIGGER IF EXISTS attendance_log_trigger ON user_profiles;
CREATE TRIGGER attendance_log_trigger
    AFTER UPDATE ON user_profiles
    FOR EACH ROW
    WHEN (OLD.is_checked_in IS DISTINCT FROM NEW.is_checked_in)
    EXECUTE FUNCTION log_attendance_change();

-- 8. Function to get user stats for dashboard
CREATE OR REPLACE FUNCTION get_user_dashboard_stats(user_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_sales', COALESCE(sales_count, 0),
        'total_sales_amount', COALESCE(sales_amount, 0),
        'monthly_check_ins', COALESCE(monthly_check_ins, 0),
        'monthly_hours', COALESCE(monthly_hours, 0),
        'current_status', CASE WHEN is_checked_in THEN 'checked_in' ELSE 'checked_out' END,
        'last_activity', last_activity
    ) INTO result
    FROM (
        SELECT 
            (SELECT COUNT(*) FROM sales WHERE created_by = user_uuid) as sales_count,
            (SELECT COALESCE(SUM(total_amount), 0) FROM sales WHERE created_by = user_uuid) as sales_amount,
            uas.monthly_check_ins,
            uas.monthly_hours,
            uas.is_checked_in,
            uas.last_activity
        FROM user_activity_summary uas
        WHERE uas.id = user_uuid
    ) stats;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 9. Create notifications table for system alerts
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

-- Enable RLS on notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own notifications
CREATE POLICY IF NOT EXISTS "Users can view own notifications" 
ON notifications FOR SELECT 
USING (auth.uid() = user_id);

-- Policy: System can insert notifications (you might want to create a service role for this)
CREATE POLICY IF NOT EXISTS "Service can insert notifications" 
ON notifications FOR INSERT 
WITH CHECK (true);

-- Policy: Users can update their own notifications (mark as read)
CREATE POLICY IF NOT EXISTS "Users can update own notifications" 
ON notifications FOR UPDATE 
USING (auth.uid() = user_id);

-- Indexes for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- 10. Sample data for testing (optional)
-- You can run this to add some test data

-- Insert sample notifications
INSERT INTO notifications (user_id, title, message, type) 
SELECT 
    id as user_id,
    'Welcome to Enhanced App!',
    'New features: Profile pictures, check-in/out, and location tracking are now available.',
    'info'
FROM user_profiles 
ON CONFLICT DO NOTHING;

-- ==========================================
-- QUERIES FOR APP ANALYTICS
-- ==========================================

-- Query to get all users with their current status
-- SELECT * FROM user_activity_summary ORDER BY last_activity DESC;

-- Query to get attendance for today
-- SELECT 
--     up.full_name,
--     al.action_type,
--     al.timestamp,
--     al.address
-- FROM attendance_log al
-- JOIN user_profiles up ON al.user_id = up.id
-- WHERE al.timestamp >= CURRENT_DATE
-- ORDER BY al.timestamp DESC;

-- Query to get sales with location data
-- SELECT 
--     s.*,
--     up.full_name as sales_person,
--     s.sale_address
-- FROM sales s
-- JOIN user_profiles up ON s.created_by = up.id
-- WHERE s.sale_address IS NOT NULL
-- ORDER BY s.created_at DESC;
