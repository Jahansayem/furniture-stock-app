-- ==========================================
-- MIGRATION: Switch from Firebase to OneSignal
-- ==========================================

-- Add OneSignal player ID field to user_profiles table
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT;

-- Create index for OneSignal player ID lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_onesignal_player_id 
ON user_profiles(onesignal_player_id);

-- Remove FCM token field if it exists (optional cleanup)
-- Uncomment the following line if you have an fcm_token column you want to remove:
-- ALTER TABLE user_profiles DROP COLUMN IF EXISTS fcm_token;

-- Update any existing notification-related functions or triggers if needed
-- (Add any custom notification logic updates here)