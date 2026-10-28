-- Manastorm affix engine v6.
--
-- Evidence sources:
--   * shutdown-era/client Spell.dbc rank families
--   * recovered ManastormMessages unlock rows
--   * preserved S9/later affix behavior
--
-- IMPORTANT:
-- The policy row at the bottom is a reconstruction default, NOT claimed
-- native Ascension probability/rank data. It exists so the engine can be
-- exercised now and tuned later without another schema rewrite.

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA=DATABASE()
     AND TABLE_NAME='manastorm_affix_catalog'
     AND COLUMN_NAME='availability_kind') = 0,
  'ALTER TABLE `manastorm_affix_catalog`
   ADD COLUMN `availability_kind` TINYINT UNSIGNED NOT NULL DEFAULT 1
   AFTER `unlock_depth`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA=DATABASE()
     AND TABLE_NAME='manastorm_affix_catalog'
     AND COLUMN_NAME='target_mask') = 0,
  'ALTER TABLE `manastorm_affix_catalog`
   ADD COLUMN `target_mask` TINYINT UNSIGNED NOT NULL DEFAULT 1
   AFTER `availability_kind`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA=DATABASE()
     AND TABLE_NAME='manastorm_affix_catalog'
     AND COLUMN_NAME='automatic_selection') = 0,
  'ALTER TABLE `manastorm_affix_catalog`
   ADD COLUMN `automatic_selection` TINYINT UNSIGNED NOT NULL DEFAULT 1
   AFTER `bounded_runtime`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA=DATABASE()
     AND TABLE_NAME='manastorm_affix_catalog'
     AND COLUMN_NAME='selection_weight') = 0,
  'ALTER TABLE `manastorm_affix_catalog`
   ADD COLUMN `selection_weight` INT UNSIGNED NOT NULL DEFAULT 100
   AFTER `automatic_selection`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Existing recovered Chapter-2 message/unlock affixes remain progression-owned.
UPDATE `manastorm_affix_catalog`
SET
  `availability_kind` = 1,
  `target_mask` = 1,
  `automatic_selection` = 1,
  `selection_weight` = 100
WHERE `affix_id` IN
  (11,13,16,19,21,23,26,28,31,33,39,41,61,101);

-- Spell.dbc proves Fungal is a living periodic aura:
--   93377 -> PERIODIC_TRIGGER_SPELL (1s) -> 93378 Fungal Summon -> helper 80914.
UPDATE `manastorm_affix_catalog`
SET
  `runtime_type` = 3,
  `death_trigger_spell_id` = 0,
  `secondary_death_trigger_spell_id` = 0,
  `apply_marker_aura` = 1,
  `bounded_runtime` = 1
WHERE `affix_id` = 31;

-- Reconstructed IDs for non-checkpoint affixes deliberately use their
-- recovered root spell IDs.  This keeps them globally unique and traceable.
INSERT INTO `manastorm_affix_catalog`
(`affix_id`,`name`,`unlock_depth`,`availability_kind`,`target_mask`,
 `runtime_type`,`root_spell_id`,`death_trigger_spell_id`,
 `secondary_death_trigger_spell_id`,`helper_creature_entry_1`,
 `helper_creature_entry_2`,`max_rank`,`apply_marker_aura`,
 `bounded_runtime`,`automatic_selection`,`selection_weight`,
 `normal_message_id`,`endgame_message_id`,`enabled`)
VALUES
(93316,  'Manastorm Meteor',      0,0,12,4,93316,0,0,663025,0,20,1,1,1,100,0,0,1),
(93341,  'Creeping Frost',        0,0,12,4,93341,0,0,80916,0,20,1,1,1,100,0,0,1),
(93344,  'Leeching',              0,0, 1,2,93344,0,0,0,0,20,1,1,1,100,0,0,1),
(93352,  'Cleaving',              0,0, 1,2,93352,0,0,0,0,20,1,1,1,100,0,0,1),
(93353,  'Unrelenting Speed',     0,0, 1,2,93353,0,0,0,0,20,1,1,1,100,0,0,1),
(93359,  'Juggernaut',            0,0, 1,2,93359,0,0,0,0, 0,1,1,1,100,0,0,1),
(93403,  'Shards of Magic',       0,0,12,4,93403,0,0,663026,0,20,1,1,1,100,0,0,1),
(93424,  'Armor Penetration',     0,0, 1,2,93424,0,0,0,0,20,1,1,1,100,0,0,1),
(93510,  'Evasive',               0,0, 1,3,93510,0,0,0,0,20,1,1,1,100,0,0,1),
(94755,  'Regenerative',          0,0, 1,2,94755,0,0,0,0,20,1,1,1,100,0,0,1),
(94756,  'Formidable',            0,0, 1,2,94756,0,0,0,0,20,1,1,1,100,0,0,1),
(94757,  'Hasty',                 0,0, 1,2,94757,0,0,0,0,20,1,1,1,100,0,0,1),
(2100261,'Guardian',              0,2, 1,2,2100261,0,0,0,0,0,1,1,0,100,0,0,1)
ON DUPLICATE KEY UPDATE
  `name`=VALUES(`name`),
  `unlock_depth`=VALUES(`unlock_depth`),
  `availability_kind`=VALUES(`availability_kind`),
  `target_mask`=VALUES(`target_mask`),
  `runtime_type`=VALUES(`runtime_type`),
  `root_spell_id`=VALUES(`root_spell_id`),
  `death_trigger_spell_id`=VALUES(`death_trigger_spell_id`),
  `secondary_death_trigger_spell_id`=VALUES(`secondary_death_trigger_spell_id`),
  `helper_creature_entry_1`=VALUES(`helper_creature_entry_1`),
  `helper_creature_entry_2`=VALUES(`helper_creature_entry_2`),
  `max_rank`=VALUES(`max_rank`),
  `apply_marker_aura`=VALUES(`apply_marker_aura`),
  `bounded_runtime`=VALUES(`bounded_runtime`),
  `automatic_selection`=VALUES(`automatic_selection`),
  `selection_weight`=VALUES(`selection_weight`),
  `enabled`=VALUES(`enabled`);

-- Spell.dbc verified 20-rank families.  Delete only rows owned by this pass.
DELETE FROM `manastorm_affix_rank_spell`
WHERE `affix_id` IN
(
  31,
  93316,93341,93344,93352,93353,93403,93424,93510,
  94755,94756,94757
);

INSERT INTO `manastorm_affix_rank_spell`
(`affix_id`,`role`,`rank`,`spell_id`)
SELECT seed.affix_id, seed.role, ranks.rank_no,
       seed.first_spell_id + ranks.rank_no - 1
FROM
(
  -- Existing Fungal was previously missing its Fungal Summon rank role.
  SELECT 31 affix_id,1 role,115251 first_spell_id UNION ALL
  SELECT 31,2,115271 UNION ALL

  SELECT 93316,1,115051 UNION ALL -- Manastorm Meteor Effect
  SELECT 93341,1,115071 UNION ALL -- Creeping Frost Effect
  SELECT 93344,1,115091 UNION ALL -- Leeching
  SELECT 93352,1,115111 UNION ALL -- Cleaving
  SELECT 93353,1,115131 UNION ALL -- Unrelenting Speed

  -- Shards has three independent ranked spell roles.
  SELECT 93403,1,115311 UNION ALL -- Shards of Magic
  SELECT 93403,2,115331 UNION ALL -- Shards of Magic Effect
  SELECT 93403,3,115351 UNION ALL -- Shards of Magic Aura

  SELECT 93424,1,115411 UNION ALL -- Armor Penetration
  SELECT 93510,1,115471 UNION ALL -- Evasive
  SELECT 94755,1,115491 UNION ALL -- Regenerative
  SELECT 94756,1,115511 UNION ALL -- Formidable
  SELECT 94757,1,115531           -- Hasty
) seed
CROSS JOIN
(
  SELECT 1 rank_no UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
  UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
  UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
  UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
) ranks;

-- Reconstructed selection policy.
-- These values are intentionally placeholders/defaults, not native claims.
CREATE TABLE IF NOT EXISTS `manastorm_affix_policy` (
  `policy_id` INT UNSIGNED NOT NULL,
  `min_depth` INT UNSIGNED NOT NULL DEFAULT 1,
  `max_depth` INT UNSIGNED NOT NULL DEFAULT 0,
  `creature_stage_affix_count` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `creature_affix_chance_pct` FLOAT NOT NULL DEFAULT 35,
  `second_affix_chance_pct` FLOAT NOT NULL DEFAULT 0,
  `boss_affix_chance_pct` FLOAT NOT NULL DEFAULT 0,
  `environment_stage_affix_count` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `default_rank` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `notes` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`policy_id`),
  KEY `idx_manastorm_affix_policy_depth`
      (`enabled`,`min_depth`,`max_depth`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `manastorm_affix_policy`
(`policy_id`,`min_depth`,`max_depth`,
 `creature_stage_affix_count`,`creature_affix_chance_pct`,
 `second_affix_chance_pct`,`boss_affix_chance_pct`,
 `environment_stage_affix_count`,`default_rank`,`enabled`,`notes`)
VALUES
(1,1,0,1,35.0,0.0,0.0,0,1,1,
 'CoA reconstruction default; replace when native selection/density/rank policy is recovered')
ON DUPLICATE KEY UPDATE
  `min_depth`=VALUES(`min_depth`),
  `max_depth`=VALUES(`max_depth`),
  `creature_stage_affix_count`=VALUES(`creature_stage_affix_count`),
  `creature_affix_chance_pct`=VALUES(`creature_affix_chance_pct`),
  `second_affix_chance_pct`=VALUES(`second_affix_chance_pct`),
  `boss_affix_chance_pct`=VALUES(`boss_affix_chance_pct`),
  `environment_stage_affix_count`=VALUES(`environment_stage_affix_count`),
  `default_rank`=VALUES(`default_rank`),
  `enabled`=VALUES(`enabled`),
  `notes`=VALUES(`notes`);

-- New authored route role.  Seed it from existing Chaotic Link candidates so
-- all work already spent marking route candidates immediately benefits affixes.
UPDATE `manastorm_segment_spawn`
SET `flags` = (`flags` | 16)
WHERE (`flags` & 2) <> 0;
