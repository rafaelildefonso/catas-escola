-- Cada execução precisa possuir seus próprios logs de steps.
-- O índice antigo por automation_id fazia execuções paralelas sobrescreverem
-- os mesmos registros.
ALTER TABLE automation_step_logs
    DROP INDEX automation_step_logs_automation_step_unique;

ALTER TABLE automation_step_logs
    ADD UNIQUE KEY automation_step_logs_run_step_unique (run_id, step_index);
