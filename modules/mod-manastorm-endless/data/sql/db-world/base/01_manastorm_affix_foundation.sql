-- Recovered Patch-M / UWEndless Manastorm affix foundation.
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
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;


CREATE TABLE IF NOT EXISTS `manastorm_affix_rank_spell` (
  `affix_id` INT UNSIGNED NOT NULL,
  `role` TINYINT UNSIGNED NOT NULL,
  `rank` TINYINT UNSIGNED NOT NULL,
  `spell_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`affix_id`,`role`,`rank`),
  KEY `idx_affix_rank_spell` (`spell_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_affix_catalog` (
  `affix_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `unlock_depth` INT UNSIGNED NOT NULL,
  `root_spell_id` INT UNSIGNED NOT NULL,
  `runtime_type` TINYINT UNSIGNED NOT NULL,
  `death_trigger_spell_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `secondary_death_trigger_spell_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `helper_creature_entry_1` INT UNSIGNED NOT NULL DEFAULT 0,
  `helper_creature_entry_2` INT UNSIGNED NOT NULL DEFAULT 0,
  `max_rank` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`affix_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `manastorm_affix_catalog`
(`affix_id`,`name`,`unlock_depth`,`root_spell_id`,`runtime_type`,
 `death_trigger_spell_id`,`secondary_death_trigger_spell_id`,
 `helper_creature_entry_1`,`helper_creature_entry_2`,`max_rank`,`enabled`)
VALUES
(11,'Mana Bomb',11,93363,1,93364,0,663028,0,20,1),
(13,'Lightning Rod',13,93354,1,93355,0,0,0,20,1),
(16,'Rampaging',16,94758,2,0,0,0,0,20,1),
(19,'Aethyric Winds',19,94749,1,94764,0,0,0,0,1),
(21,'Cold Snap',21,93444,1,93445,0,80924,80925,20,1),
(23,'Tribal Fury',23,93422,2,0,0,0,0,20,1),
(26,'Vortex',26,93381,1,93382,0,0,0,20,1),
(28,'Stalwart',28,94760,2,0,0,0,0,20,1),
(31,'Fungal',31,93377,1,93378,0,80914,0,20,1),
(33,'Wild Magics',33,93425,2,0,0,80922,80923,20,1),
(39,'Runes of Power',39,94752,1,94753,94762,0,0,0,1),
(41,'Reflecting',41,93360,2,0,0,0,0,20,1),
(61,'Bone Storm',61,93366,1,93367,0,80913,0,20,1),
(101,'Overwhelming Energy',101,93383,1,93408,0,80917,0,20,1)
ON DUPLICATE KEY UPDATE
  `name`=VALUES(`name`),
  `unlock_depth`=VALUES(`unlock_depth`),
  `root_spell_id`=VALUES(`root_spell_id`),
  `runtime_type`=VALUES(`runtime_type`),
  `death_trigger_spell_id`=VALUES(`death_trigger_spell_id`),
  `secondary_death_trigger_spell_id`=VALUES(`secondary_death_trigger_spell_id`),
  `helper_creature_entry_1`=VALUES(`helper_creature_entry_1`),
  `helper_creature_entry_2`=VALUES(`helper_creature_entry_2`),
  `max_rank`=VALUES(`max_rank`),
  `enabled`=1;


-- Recovered sequential rank families. Historical depth-to-rank selection
-- remains intentionally unimplemented until recovered.
DELETE FROM `manastorm_affix_rank_spell`
WHERE `affix_id` IN (11,13,16,21,23,26,28,31,33,41,61,101);

INSERT INTO `manastorm_affix_rank_spell`
(`affix_id`,`role`,`rank`,`spell_id`)
SELECT a.affix_id, a.role, r.n, a.first_spell + r.n - 1
FROM (
  SELECT 11 affix_id,1 role,93490 first_spell UNION ALL
  SELECT 11,2,115211 UNION ALL
  SELECT 13,1,115151 UNION ALL
  SELECT 13,2,115171 UNION ALL
  SELECT 16,1,115551 UNION ALL
  SELECT 21,1,115451 UNION ALL
  SELECT 23,1,115391 UNION ALL
  SELECT 26,1,115371 UNION ALL
  SELECT 28,1,115571 UNION ALL
  SELECT 31,1,115271 UNION ALL
  SELECT 33,1,115431 UNION ALL
  SELECT 41,1,115191 UNION ALL
  SELECT 61,1,115231 UNION ALL
  SELECT 101,1,115291
) a
CROSS JOIN (
  SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
  UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
  UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
  UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
) r;

INSERT INTO `manastorm_unlock`
(`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,
 `intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,
 `completion_message_id`,`enabled`)
VALUES
(900011,1,11,15,3,0,0,0,804,1),
(900013,1,13,15,3,0,0,0,805,1),
(900016,1,16,15,3,0,0,0,807,1),
(900019,1,19,15,3,0,0,0,808,1),
(900021,1,21,15,3,0,0,0,811,1),
(900023,1,23,15,3,0,0,0,809,1),
(900026,1,26,15,3,0,0,0,806,1),
(900028,1,28,15,3,0,0,0,810,1),
(900031,1,31,15,3,0,0,0,830,1),
(900033,1,33,15,3,0,0,0,812,1),
(900039,1,39,15,3,0,0,0,815,1),
(900041,1,41,15,3,0,0,0,814,1),
(900061,1,61,15,3,0,0,0,816,1),
(900101,1,101,15,3,0,0,0,813,1)
ON DUPLICATE KEY UPDATE
  `unlock_kind`=1,
  `trigger_depth`=VALUES(`trigger_depth`),
  `mode_mask`=VALUES(`mode_mask`),
  `track_mask`=VALUES(`track_mask`),
  `intro_segment_id`=0,
  `endgame_intro_segment_id`=0,
  `intro_message_id`=0,
  `completion_message_id`=VALUES(`completion_message_id`),
  `enabled`=1;

INSERT INTO `manastorm_unlock_grant`
(`unlock_id`,`grant_type`,`content_id`,`enabled`)
VALUES
(900011,4,11,1),(900013,4,13,1),(900016,4,16,1),(900019,4,19,1),
(900021,4,21,1),(900023,4,23,1),(900026,4,26,1),(900028,4,28,1),
(900031,4,31,1),(900033,4,33,1),(900039,4,39,1),(900041,4,41,1),
(900061,4,61,1),(900101,4,101,1)
ON DUPLICATE KEY UPDATE `enabled`=1;
