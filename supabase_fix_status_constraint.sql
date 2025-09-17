-- Fix sales status check constraint to include 'in_review' status
-- Run this in Supabase SQL Editor

-- First, let's see the current constraint
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'sales' 
AND c.contype = 'c'
AND conname LIKE '%status%';

-- Drop the existing constraint
ALTER TABLE sales DROP CONSTRAINT IF EXISTS sales_status_check;

-- Add the new constraint with 'in_review' status included
ALTER TABLE sales ADD CONSTRAINT sales_status_check 
CHECK (status IN ('pending', 'completed', 'cancelled', 'in_review'));

-- Verify the constraint was created correctly
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'sales' 
AND c.contype = 'c'
AND conname = 'sales_status_check';