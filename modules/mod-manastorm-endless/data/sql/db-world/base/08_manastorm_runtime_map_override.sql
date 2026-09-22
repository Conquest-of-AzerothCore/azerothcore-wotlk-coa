-- Native Manastorm segment identity and physical server execution may differ.
--
-- map_id remains the original Manastorm.dbc identity used by native Mode 2.
-- runtime_map_id is an opt-in physical server map override.
-- 0 means "execute on map_id", preserving all existing behavior.
--
-- This is intentionally data-neutral: no segment override is guessed here.
-- Author an override only after the physical source area has been verified.
--
-- Compatibility note:
-- Some MySQL/MariaDB versions used by AzerothCore do not support
-- "ADD COLUMN IF NOT EXISTS". Use an information_schema guard instead so
-- this migration remains safe to re-run.

SET @manastorm_runtime_map_column_exists := (
    SELECT COUNT(*)
    FROM `information_schema`.`COLUMNS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'manastorm_segment'
      AND `COLUMN_NAME` = 'runtime_map_id'
);

SET @manastorm_runtime_map_sql := IF(
    @manastorm_runtime_map_column_exists = 0,
    'ALTER TABLE `manastorm_segment` ADD COLUMN `runtime_map_id` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `map_id`',
    'SELECT 1'
);

PREPARE manastorm_runtime_map_stmt
    FROM @manastorm_runtime_map_sql;

EXECUTE manastorm_runtime_map_stmt;

DEALLOCATE PREPARE manastorm_runtime_map_stmt;

SET @manastorm_runtime_map_sql := NULL;
SET @manastorm_runtime_map_column_exists := NULL;
