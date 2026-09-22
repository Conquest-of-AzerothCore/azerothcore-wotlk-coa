-- Native/imported objective identity and physical server execution may differ.
--
-- objective_creature_entry remains the recovered segment objective identity.
-- runtime_objective_creature_entry is an opt-in physical server creature-entry
-- override used for runtime boss detection, Hearts, Chaotic Link state and
-- completion. 0 means "use objective_creature_entry".
--
-- This is intentionally data-neutral: no objective override is guessed here.
-- Author an override only after the equivalent physical source creature has
-- been verified.
--
-- Compatibility note:
-- Some MySQL/MariaDB versions used by AzerothCore do not support
-- "ADD COLUMN IF NOT EXISTS". Use an information_schema guard instead so
-- this migration remains safe to re-run.

SET @manastorm_runtime_objective_column_exists := (
    SELECT COUNT(*)
    FROM `information_schema`.`COLUMNS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'manastorm_segment'
      AND `COLUMN_NAME` = 'runtime_objective_creature_entry'
);

SET @manastorm_runtime_objective_sql := IF(
    @manastorm_runtime_objective_column_exists = 0,
    'ALTER TABLE `manastorm_segment` ADD COLUMN `runtime_objective_creature_entry` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `objective_creature_entry`',
    'SELECT 1'
);

PREPARE manastorm_runtime_objective_stmt
    FROM @manastorm_runtime_objective_sql;

EXECUTE manastorm_runtime_objective_stmt;

DEALLOCATE PREPARE manastorm_runtime_objective_stmt;

SET @manastorm_runtime_objective_sql := NULL;
SET @manastorm_runtime_objective_column_exists := NULL;
