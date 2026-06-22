-- Add intent field to automation_step_logs table
-- This allows the frontend to display what the backend is actually executing

ALTER TABLE automation_step_logs 
ADD COLUMN IF NOT EXISTS intent TEXT;

-- Add comment for documentation
COMMENT ON COLUMN automation_step_logs.intent IS 'Intent/objective of the automation (e.g., gemini_action, calendar_create_event, etc.)';
