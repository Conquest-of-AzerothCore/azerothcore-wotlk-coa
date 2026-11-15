CREATE TABLE IF NOT EXISTS `character_manastorm_coa_token_window` (
  `guid` INT UNSIGNED NOT NULL,
  `window_start` INT UNSIGNED NOT NULL,
  `window_end` INT UNSIGNED NOT NULL,
  `tokens_earned` INT UNSIGNED NOT NULL DEFAULT 0,
  `revision` BIGINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`guid`),
  CONSTRAINT `chk_manastorm_coa_token_revision` CHECK (`revision` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `character_manastorm_coa_token_clear` (
  `guid` INT UNSIGNED NOT NULL,
  `mode` TINYINT UNSIGNED NOT NULL,
  `track` TINYINT UNSIGNED NOT NULL,
  `depth` INT UNSIGNED NOT NULL,
  `window_start` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`, `mode`, `track`, `depth`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
