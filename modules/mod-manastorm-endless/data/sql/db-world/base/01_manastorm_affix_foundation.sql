-- Patch-M Manastorm Affix Foundation
-- Full recovered catalogue preserved from the prior v4 forensic foundation.
-- Runtime affix IDs are shared server IDs, not proven native protocol IDs.
-- Automatic historical affix density/rank selection remains intentionally disabled.

SET @has_unlock_kind := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'manastorm_unlock'
    AND COLUMN_NAME = 'unlock_kind'
);
SET @sql := IF(
  @has_unlock_kind = 0,
  'ALTER TABLE `manastorm_unlock` ADD COLUMN `unlock_kind` TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `unlock_id`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS `manastorm_affix_catalog` (
  `affix_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `unlock_depth` INT UNSIGNED NOT NULL,
  `runtime_type` TINYINT UNSIGNED NOT NULL,
  `root_spell_id` INT UNSIGNED NOT NULL,
  `death_trigger_spell_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `secondary_death_trigger_spell_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `helper_creature_entry_1` INT UNSIGNED NOT NULL DEFAULT 0,
  `helper_creature_entry_2` INT UNSIGNED NOT NULL DEFAULT 0,
  `max_rank` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `apply_marker_aura` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `bounded_runtime` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `normal_message_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `endgame_message_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`affix_id`),
  KEY `idx_affix_unlock_depth` (`unlock_depth`,`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='manastorm_affix_catalog' AND COLUMN_NAME='apply_marker_aura') = 0,
  'ALTER TABLE `manastorm_affix_catalog` ADD COLUMN `apply_marker_aura` TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER `max_rank`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='manastorm_affix_catalog' AND COLUMN_NAME='bounded_runtime') = 0,
  'ALTER TABLE `manastorm_affix_catalog` ADD COLUMN `bounded_runtime` TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `apply_marker_aura`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='manastorm_affix_catalog' AND COLUMN_NAME='normal_message_id') = 0,
  'ALTER TABLE `manastorm_affix_catalog` ADD COLUMN `normal_message_id` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `bounded_runtime`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='manastorm_affix_catalog' AND COLUMN_NAME='endgame_message_id') = 0,
  'ALTER TABLE `manastorm_affix_catalog` ADD COLUMN `endgame_message_id` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `normal_message_id`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS `manastorm_affix_rank_spell` (
  `affix_id` INT UNSIGNED NOT NULL,
  `role` TINYINT UNSIGNED NOT NULL,
  `rank` TINYINT UNSIGNED NOT NULL,
  `spell_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`affix_id`,`role`,`rank`),
  KEY `idx_affix_rank_spell` (`spell_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `manastorm_affix_catalog`
(`affix_id`,`name`,`unlock_depth`,`runtime_type`,`root_spell_id`,
 `death_trigger_spell_id`,`secondary_death_trigger_spell_id`,
 `helper_creature_entry_1`,`helper_creature_entry_2`,`max_rank`,
 `apply_marker_aura`,`bounded_runtime`,`normal_message_id`,
 `endgame_message_id`,`enabled`)
VALUES
(11,'Mana Bomb',11,1,93363,93364,0,663028,0,20,1,1,804,817,1),
(13,'Lightning Rod',13,1,93354,93355,0,0,0,20,1,1,805,818,1),
(16,'Rampaging',16,2,94758,0,0,0,0,20,1,1,807,820,1),
(19,'Aethyric Winds',19,1,94749,94764,0,0,0,0,1,1,808,821,1),
(21,'Cold Snap',21,1,93444,93445,0,80924,80925,20,1,0,811,824,1),
(23,'Tribal Fury',23,2,93422,0,0,0,0,20,1,1,809,822,1),
(26,'Vortex',26,1,93381,93382,0,663029,0,20,1,1,806,819,1),
(28,'Stalwart',28,2,94760,0,0,0,0,20,1,1,810,823,1),
(31,'Fungal',31,3,93377,0,0,80914,0,20,1,1,830,831,1),
(33,'Wild Magics',33,2,93425,0,0,80922,80923,20,1,0,812,825,1),
(39,'Runes of Power',39,1,94752,94753,94762,0,0,0,1,1,815,828,1),
(41,'Reflecting',41,2,93360,0,0,0,0,20,1,0,814,827,1),
(61,'Bone Storm',61,1,93366,93367,0,80913,0,20,1,0,816,829,1),
(101,'Overwhelming Energy',101,1,93383,93408,0,80917,0,20,1,0,813,826,1)
ON DUPLICATE KEY UPDATE
  `name`=VALUES(`name`),
  `unlock_depth`=VALUES(`unlock_depth`),
  `runtime_type`=VALUES(`runtime_type`),
  `root_spell_id`=VALUES(`root_spell_id`),
  `death_trigger_spell_id`=VALUES(`death_trigger_spell_id`),
  `secondary_death_trigger_spell_id`=VALUES(`secondary_death_trigger_spell_id`),
  `helper_creature_entry_1`=VALUES(`helper_creature_entry_1`),
  `helper_creature_entry_2`=VALUES(`helper_creature_entry_2`),
  `max_rank`=VALUES(`max_rank`),
  `apply_marker_aura`=VALUES(`apply_marker_aura`),
  `bounded_runtime`=VALUES(`bounded_runtime`),
  `normal_message_id`=VALUES(`normal_message_id`),
  `endgame_message_id`=VALUES(`endgame_message_id`),
  `enabled`=VALUES(`enabled`);

DELETE FROM `manastorm_affix_rank_spell`
WHERE `affix_id` IN (11,13,16,21,23,26,28,31,33,41,61,101);

INSERT INTO `manastorm_affix_rank_spell`
(`affix_id`,`role`,`rank`,`spell_id`)
SELECT seed.affix_id, seed.role, ranks.rank_no,
       seed.first_spell_id + ranks.rank_no - 1
FROM (
  SELECT 11 affix_id,1 role,93490 first_spell_id UNION ALL
  SELECT 11,2,115211 UNION ALL
  SELECT 13,1,115151 UNION ALL
  SELECT 13,2,115171 UNION ALL
  SELECT 16,1,115551 UNION ALL
  SELECT 21,1,115451 UNION ALL
  SELECT 23,1,115391 UNION ALL
  SELECT 26,1,115371 UNION ALL
  SELECT 28,1,115571 UNION ALL
  SELECT 31,1,115251 UNION ALL
  SELECT 31,2,115271 UNION ALL
  SELECT 33,1,115431 UNION ALL
  SELECT 41,1,115191 UNION ALL
  SELECT 61,1,115231 UNION ALL
  SELECT 101,1,115291
) seed
CROSS JOIN (
  SELECT 1 rank_no UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
  UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
  UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
  UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
) ranks;

INSERT INTO `manastorm_unlock`
(`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,
 `intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,
 `completion_message_id`,`enabled`)
VALUES
(900011,1,11,15,3,0,0,0,804,0),
(900013,1,13,15,3,0,0,0,805,0),
(900016,1,16,15,3,0,0,0,807,0),
(900019,1,19,15,3,0,0,0,808,0),
(900021,1,21,15,3,0,0,0,811,0),
(900023,1,23,15,3,0,0,0,809,0),
(900026,1,26,15,3,0,0,0,806,0),
(900028,1,28,15,3,0,0,0,810,0),
(900031,1,31,15,3,0,0,0,830,0),
(900033,1,33,15,3,0,0,0,812,0),
(900039,1,39,15,3,0,0,0,815,0),
(900041,1,41,15,3,0,0,0,814,0),
(900061,1,61,15,3,0,0,0,816,0),
(900101,1,101,15,3,0,0,0,813,0)
ON DUPLICATE KEY UPDATE
  `unlock_kind`=VALUES(`unlock_kind`),
  `trigger_depth`=VALUES(`trigger_depth`),
  `mode_mask`=VALUES(`mode_mask`),
  `track_mask`=VALUES(`track_mask`),
  `intro_segment_id`=0,
  `endgame_intro_segment_id`=0,
  `intro_message_id`=0,
  `completion_message_id`=VALUES(`completion_message_id`),
  `enabled`=0;

INSERT INTO `manastorm_unlock_grant`
(`unlock_id`,`grant_type`,`content_id`,`enabled`)
VALUES
(900011,4,11,0),
(900013,4,13,0),
(900016,4,16,0),
(900019,4,19,0),
(900021,4,21,0),
(900023,4,23,0),
(900026,4,26,0),
(900028,4,28,0),
(900031,4,31,0),
(900033,4,33,0),
(900039,4,39,0),
(900041,4,41,0),
(900061,4,61,0),
(900101,4,101,0)
ON DUPLICATE KEY UPDATE
  `enabled`=0;
