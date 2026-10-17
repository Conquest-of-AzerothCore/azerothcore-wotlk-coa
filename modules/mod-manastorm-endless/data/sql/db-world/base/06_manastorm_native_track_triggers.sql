-- Native Mode-2 progression trigger normalization.
--
-- A permanent unlock can trigger at a different completion depth on Normal
-- and Endgame. Patch-M proves this with Warchief Rend Blackhand:
-- Normal=395, Endgame=380.
--
-- Existing manastorm_unlock.trigger_depth/track_mask are retained only as
-- import/migration compatibility. Runtime authority moves to this table.

CREATE TABLE IF NOT EXISTS `manastorm_unlock_trigger` (
  `unlock_id` INT UNSIGNED NOT NULL,
  `track` TINYINT UNSIGNED NOT NULL,
  `trigger_depth` INT UNSIGNED NOT NULL,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`unlock_id`,`track`),
  KEY `idx_native_trigger` (`track`,`trigger_depth`,`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `manastorm_unlock_trigger`
    (`unlock_id`, `track`, `trigger_depth`, `enabled`)
SELECT `unlock_id`, 1, `trigger_depth`, `enabled`
FROM `manastorm_unlock`
WHERE (`track_mask` & 1) <> 0
  AND `trigger_depth` > 0
ON DUPLICATE KEY UPDATE
    `trigger_depth` = VALUES(`trigger_depth`),
    `enabled` = VALUES(`enabled`);

INSERT INTO `manastorm_unlock_trigger`
    (`unlock_id`, `track`, `trigger_depth`, `enabled`)
SELECT `unlock_id`, 2, `trigger_depth`, `enabled`
FROM `manastorm_unlock`
WHERE (`track_mask` & 2) <> 0
  AND `trigger_depth` > 0
ON DUPLICATE KEY UPDATE
    `trigger_depth` = VALUES(`trigger_depth`),
    `enabled` = VALUES(`enabled`);

SELECT `track`,
       COUNT(*) AS enabled_triggers,
       MIN(`trigger_depth`) AS first_depth,
       MAX(`trigger_depth`) AS last_depth
FROM `manastorm_unlock_trigger`
WHERE `enabled` = 1
GROUP BY `track`
ORDER BY `track`;
