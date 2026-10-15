CREATE TABLE IF NOT EXISTS `coa_mystic_enchant` (
  `guid` INT UNSIGNED NOT NULL,
  `progress` BIGINT UNSIGNED NOT NULL DEFAULT 1,
  `level` INT UNSIGNED NOT NULL DEFAULT 1,
  `active_preset` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `preset_count` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `coa_mystic_enchant_known` (
  `guid` INT UNSIGNED NOT NULL,
  `spell` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`, `spell`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `coa_mystic_enchant_slot` (
  `guid` INT UNSIGNED NOT NULL,
  `preset` TINYINT UNSIGNED NOT NULL,
  `slot` TINYINT UNSIGNED NOT NULL,
  `spell` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`, `preset`, `slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
