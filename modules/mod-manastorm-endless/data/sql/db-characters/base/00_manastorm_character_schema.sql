-- mod-manastorm-endless character database schema

CREATE TABLE IF NOT EXISTS `character_manastorm_progress` (
  `guid` INT UNSIGNED NOT NULL,
  `mode` TINYINT UNSIGNED NOT NULL,
  `track` TINYINT UNSIGNED NOT NULL,
  `best_completed_depth` INT UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`,`mode`,`track`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `character_manastorm_completed_depth` (
  `guid` INT UNSIGNED NOT NULL,
  `mode` TINYINT UNSIGNED NOT NULL,
  `track` TINYINT UNSIGNED NOT NULL,
  `depth` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`,`mode`,`track`,`depth`),
  KEY `idx_guid_track` (`guid`,`track`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `character_manastorm_unlock` (
  `guid` INT UNSIGNED NOT NULL,
  `unlock_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`,`unlock_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `character_manastorm_pending_unlock` (
  `guid` INT UNSIGNED NOT NULL,
  `mode` TINYINT UNSIGNED NOT NULL,
  `track` TINYINT UNSIGNED NOT NULL,
  `unlock_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`,`mode`,`track`),
  KEY `idx_unlock_id` (`unlock_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
