CREATE TABLE IF NOT EXISTS `character_manastorm_weekly_cache` (
  `guid` INT UNSIGNED NOT NULL,
  `reset_time` INT UNSIGNED NOT NULL,
  `cache_number` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`, `reset_time`, `cache_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `character_manastorm_stage_receipt` (
  `guid` INT UNSIGNED NOT NULL,
  `run_seed` BIGINT UNSIGNED NOT NULL,
  `run_id` BIGINT UNSIGNED NOT NULL,
  `depth` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`, `run_seed`, `run_id`, `depth`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
