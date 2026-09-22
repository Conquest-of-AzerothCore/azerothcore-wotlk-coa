-- Native Mode-2 eight-category progression storage.
-- Run once on the existing character database after pulling this commit.

SET @has_progress_track := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'character_manastorm_progress'
    AND COLUMN_NAME = 'track'
);
SET @sql := IF(
  @has_progress_track = 0,
  'ALTER TABLE `character_manastorm_progress` ADD COLUMN `track` TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER `mode`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @progress_pk_cols := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'character_manastorm_progress'
    AND INDEX_NAME = 'PRIMARY'
);
SET @sql := IF(
  @progress_pk_cols = 2,
  'ALTER TABLE `character_manastorm_progress` DROP PRIMARY KEY, ADD PRIMARY KEY (`guid`,`mode`,`track`)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

INSERT IGNORE INTO `character_manastorm_progress`
    (`guid`, `mode`, `track`, `best_completed_depth`, `updated_at`)
SELECT `guid`, `mode`, 2, `best_completed_depth`, `updated_at`
FROM `character_manastorm_progress`
WHERE `track` = 1;

SET @has_pending_track := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'character_manastorm_pending_unlock'
    AND COLUMN_NAME = 'track'
);
SET @sql := IF(
  @has_pending_track = 0,
  'ALTER TABLE `character_manastorm_pending_unlock` ADD COLUMN `track` TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER `mode`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @pending_pk_cols := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'character_manastorm_pending_unlock'
    AND INDEX_NAME = 'PRIMARY'
);
SET @sql := IF(
  @pending_pk_cols = 2,
  'ALTER TABLE `character_manastorm_pending_unlock` DROP PRIMARY KEY, ADD PRIMARY KEY (`guid`,`mode`,`track`)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

INSERT IGNORE INTO `character_manastorm_pending_unlock`
    (`guid`, `mode`, `track`, `unlock_id`)
SELECT `guid`, `mode`, 2, `unlock_id`
FROM `character_manastorm_pending_unlock`
WHERE `track` = 1;

CREATE TABLE IF NOT EXISTS `character_manastorm_completed_depth` (
  `guid` INT UNSIGNED NOT NULL,
  `mode` TINYINT UNSIGNED NOT NULL,
  `track` TINYINT UNSIGNED NOT NULL,
  `depth` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`,`mode`,`track`,`depth`),
  KEY `idx_guid_track` (`guid`,`track`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `character_manastorm_completed_depth`
    (`guid`, `mode`, `track`, `depth`)
SELECT `guid`, `mode`, `track`, `best_completed_depth`
FROM `character_manastorm_progress`
WHERE `best_completed_depth` > 0;

SELECT `track`, COUNT(*) AS progress_rows,
       MAX(`best_completed_depth`) AS highest_best
FROM `character_manastorm_progress`
GROUP BY `track`
ORDER BY `track`;

SELECT `track`, COUNT(*) AS persisted_completed_depths
FROM `character_manastorm_completed_depth`
GROUP BY `track`
ORDER BY `track`;
