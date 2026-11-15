CREATE TABLE IF NOT EXISTS `character_manastorm_coa_encounter` (
  `receipt` VARCHAR(96) NOT NULL,
  `guid` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`receipt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
