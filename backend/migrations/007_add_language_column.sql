-- =========================================================
-- ADD LANGUAGE COLUMN TO PROFILES
-- =========================================================

-- Add language column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS language text DEFAULT 'en';

-- Update existing profiles to detect their language based on metadata or default to system
-- For now, we'll set existing profiles to 'en' as a safe default
UPDATE public.profiles 
SET language = 'en' 
WHERE language IS NULL OR language = '';

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_profiles_language ON public.profiles(language);

-- =========================================================
-- FIM - MIGRATION 007
-- =========================================================
