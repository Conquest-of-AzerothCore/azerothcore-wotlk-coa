-- mod-manastorm-endless world database schema
-- No gameplay rows are guessed here. Import your authored segment/unlock data separately.

CREATE TABLE IF NOT EXISTS `manastorm_segment` (
  `segment_id` INT UNSIGNED NOT NULL,
  `map_id` INT UNSIGNED NOT NULL,
  `difficulty` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `dungeon_encounter_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `objective_creature_entry` INT UNSIGNED NOT NULL,
  `start_game_tele_id` INT UNSIGNED NOT NULL,
  `weight` INT UNSIGNED NOT NULL DEFAULT 1,
  `min_depth` INT UNSIGNED NOT NULL DEFAULT 1,
  `max_depth` INT UNSIGNED NOT NULL DEFAULT 0,
  `reward_multiplier` FLOAT NOT NULL DEFAULT 1,
  `chaotic_link_stacks` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `flags` INT UNSIGNED NOT NULL DEFAULT 0,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`segment_id`),
  KEY `idx_enabled_depth` (`enabled`,`min_depth`,`max_depth`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_chaotic_link_spawn` (
  `segment_id` INT UNSIGNED NOT NULL,
  `spawn_guid` INT UNSIGNED NOT NULL,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`segment_id`,`spawn_guid`),
  KEY `idx_spawn_guid` (`spawn_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_scaling_curve` (
  `depth` INT UNSIGNED NOT NULL,
  `health_multiplier` FLOAT NOT NULL DEFAULT 1,
  `global_damage_multiplier` FLOAT NOT NULL DEFAULT 1,
  `melee_multiplier` FLOAT NOT NULL DEFAULT 1,
  `spell_multiplier` FLOAT NOT NULL DEFAULT 1,
  PRIMARY KEY (`depth`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_unlock` (
  `unlock_id` INT UNSIGNED NOT NULL,
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
