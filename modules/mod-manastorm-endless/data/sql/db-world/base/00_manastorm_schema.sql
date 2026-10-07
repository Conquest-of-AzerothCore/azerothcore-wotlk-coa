-- mod-manastorm-endless world database schema
-- No gameplay rows are guessed here. Import your authored segment/unlock data separately.

CREATE TABLE IF NOT EXISTS `manastorm_segment` (
  `segment_id` INT UNSIGNED NOT NULL,
  `map_id` INT UNSIGNED NOT NULL,
  -- Optional physical server-map override. The explicit enable flag keeps
  -- runtime map 0 (Eastern Kingdoms) representable while preserving legacy
  -- rows where runtime_map_id=0 meant "use native map_id".
  `runtime_map_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `runtime_map_override_enabled` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `difficulty` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `dungeon_encounter_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `objective_creature_entry` INT UNSIGNED NOT NULL,
  -- Optional physical server objective override. 0 preserves the recovered
  -- native/imported objective identity and uses objective_creature_entry.
  `runtime_objective_creature_entry` INT UNSIGNED NOT NULL DEFAULT 0,
  `start_game_tele_id` INT UNSIGNED NOT NULL,
  `weight` INT UNSIGNED NOT NULL DEFAULT 1,
  `min_depth` INT UNSIGNED NOT NULL DEFAULT 1,
  `max_depth` INT UNSIGNED NOT NULL DEFAULT 0,
  -- Reconstructed/custom-mode reward scalar. In native ClientMode=2 the
  -- untouched Manastorm.dbc w4/w5 reward values are authoritative for payout;
  -- this SQL value is retained as the non-native/fallback authoring field.
  `reward_multiplier` FLOAT NOT NULL DEFAULT 1,
  `chaotic_link_stacks` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `flags` INT UNSIGNED NOT NULL DEFAULT 0,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`segment_id`),
  KEY `idx_enabled_depth` (`enabled`,`min_depth`,`max_depth`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Authoritative authored roster for persistent DB spawns belonging to a
-- Manastorm segment. One row may carry several independent roles.
-- flags:
--   0x01 RouteCreature
--   0x02 ChaoticLinkEligible
--   0x04 RandomizationSlot       (recorded only; replacement runtime disabled)
--   0x08 CreaturePoolSource      (may contribute its native creature entry)
CREATE TABLE IF NOT EXISTS `manastorm_segment_spawn` (
  `segment_id` INT UNSIGNED NOT NULL,
  `spawn_guid` INT UNSIGNED NOT NULL,
  `flags` INT UNSIGNED NOT NULL DEFAULT 1,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`segment_id`,`spawn_guid`),
  KEY `idx_spawn_guid` (`spawn_guid`),
  KEY `idx_segment_flags` (`segment_id`,`flags`,`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Legacy compatibility table. New authoring belongs in
-- manastorm_segment_spawn. 05_manastorm_segment_pool_architecture.sql copies
-- existing rows as RouteCreature|ChaoticLinkEligible without guessing any
-- randomization or creature-pool eligibility.
CREATE TABLE IF NOT EXISTS `manastorm_chaotic_link_spawn` (
  `segment_id` INT UNSIGNED NOT NULL,
  `spawn_guid` INT UNSIGNED NOT NULL,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`segment_id`,`spawn_guid`),
  KEY `idx_spawn_guid` (`spawn_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_creature_pool` (
  `pool_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(120) NOT NULL DEFAULT '',
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`pool_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Pools reference authored source segments rather than duplicating thousands
-- of creature-entry rows. Candidate creature entries are derived from each
-- source segment's CreaturePoolSource spawn roles.
CREATE TABLE IF NOT EXISTS `manastorm_creature_pool_segment` (
  `pool_id` INT UNSIGNED NOT NULL,
  `segment_id` INT UNSIGNED NOT NULL,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`pool_id`,`segment_id`),
  KEY `idx_source_segment` (`segment_id`,`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_scaling_curve` (
  `depth` INT UNSIGNED NOT NULL,
  `health_multiplier` FLOAT NOT NULL DEFAULT 1,
  `global_damage_multiplier` FLOAT NOT NULL DEFAULT 1,
  `melee_multiplier` FLOAT NOT NULL DEFAULT 1,
  `spell_multiplier` FLOAT NOT NULL DEFAULT 1,
  PRIMARY KEY (`depth`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optional second scaling layer by live Manastorm member count.
-- Rows are non-overlapping inclusive ranges:
--   1-15 = one generic group profile
--   1-1, 2-2, 3-3, 4-15 = Solo/Duo/Trio/Group-style profiles
--   1-1 ... 15-15 = exact per-count profiles
-- Missing member counts are neutral 1.0x and therefore keep the depth curve.
CREATE TABLE IF NOT EXISTS `manastorm_group_scaling` (
  `min_members` TINYINT UNSIGNED NOT NULL,
  `max_members` TINYINT UNSIGNED NOT NULL,
  `health_multiplier` FLOAT NOT NULL DEFAULT 1,
  `global_damage_multiplier` FLOAT NOT NULL DEFAULT 1,
  `melee_multiplier` FLOAT NOT NULL DEFAULT 1,
  `spell_multiplier` FLOAT NOT NULL DEFAULT 1,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`min_members`,`max_members`),
  KEY `idx_group_scaling_enabled` (`enabled`,`min_members`,`max_members`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_unlock` (
  `unlock_id` INT UNSIGNED NOT NULL,
  `unlock_kind` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `trigger_depth` INT UNSIGNED NOT NULL,
  `mode_mask` TINYINT UNSIGNED NOT NULL DEFAULT 15,
  `track_mask` TINYINT UNSIGNED NOT NULL DEFAULT 3,
  `intro_segment_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `endgame_intro_segment_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `intro_message_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `completion_message_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`unlock_id`),
  KEY `idx_trigger_depth` (`trigger_depth`,`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_unlock_trigger` (
  `unlock_id` INT UNSIGNED NOT NULL,
  -- Exact native track bit: 1=Normal, 2=Endgame.
  `track` TINYINT UNSIGNED NOT NULL,
  `trigger_depth` INT UNSIGNED NOT NULL,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`unlock_id`,`track`),
  KEY `idx_native_trigger` (`track`,`trigger_depth`,`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_unlock_grant` (
  `unlock_id` INT UNSIGNED NOT NULL,
  `grant_type` TINYINT UNSIGNED NOT NULL,
  `content_id` INT UNSIGNED NOT NULL,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`unlock_id`,`grant_type`,`content_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_unlock_message` (
  `message_id` INT UNSIGNED NOT NULL,
  `icon` VARCHAR(255) NOT NULL DEFAULT '',
  `title` VARCHAR(255) NOT NULL DEFAULT '',
  `description` TEXT NOT NULL,
  PRIMARY KEY (`message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
