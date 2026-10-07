-- Allow explicit physical runtime map 0 (Eastern Kingdoms).
--
-- Historically runtime_map_id=0 meant "no override". That made map 0
-- impossible to target. Keep old rows backwards-compatible by adding an
-- explicit enable bit, then mark every existing non-zero override as enabled.

SET @manastorm_runtime_map_override_column_exists := (
    SELECT COUNT(*)
    FROM `information_schema`.`COLUMNS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'manastorm_segment'
      AND `COLUMN_NAME` = 'runtime_map_override_enabled'
);

SET @manastorm_runtime_map_override_sql := IF(
    @manastorm_runtime_map_override_column_exists = 0,
    'ALTER TABLE `manastorm_segment` ADD COLUMN `runtime_map_override_enabled` TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `runtime_map_id`',
    'SELECT 1'
);

PREPARE manastorm_runtime_map_override_stmt
    FROM @manastorm_runtime_map_override_sql;

EXECUTE manastorm_runtime_map_override_stmt;

DEALLOCATE PREPARE manastorm_runtime_map_override_stmt;

UPDATE `manastorm_segment`
SET `runtime_map_override_enabled` = 1
WHERE `runtime_map_id` <> 0;

SET @manastorm_runtime_map_override_sql := NULL;
SET @manastorm_runtime_map_override_column_exists := NULL;
