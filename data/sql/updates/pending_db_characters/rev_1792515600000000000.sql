CREATE TABLE IF NOT EXISTS `manastorm_weekly_cache_lockout` (
  `guid` INT UNSIGNED NOT NULL,
  `reset_at` INT UNSIGNED NOT NULL,
  `caches_received` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`),
  CONSTRAINT `chk_manastorm_weekly_reset` CHECK (`reset_at` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
