-- =========================================================
-- MIGRATION 007: ADD LANGUAGE COLUMN TO PROFILES (MySQL)
-- =========================================================

SET @col_language := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'profiles' AND column_name = 'language');
SET @sql_language := IF(@col_language = 0,
    'ALTER TABLE profiles ADD COLUMN language VARCHAR(255) DEFAULT ''en''', 'SELECT 1');
PREPARE stmt_language FROM @sql_language;
EXECUTE stmt_language;
DEALLOCATE PREPARE stmt_language;

-- Update existing profiles to a safe default
UPDATE profiles
SET language = 'en'
WHERE language IS NULL OR language = '';

-- Índice para consultas mais rápidas
CREATE INDEX idx_profiles_language ON profiles(language);