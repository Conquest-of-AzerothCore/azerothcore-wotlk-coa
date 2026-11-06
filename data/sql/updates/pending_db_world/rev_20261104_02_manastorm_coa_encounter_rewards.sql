CREATE TABLE IF NOT EXISTS `manastorm_coa_encounter_rewards` (
  `source` TINYINT UNSIGNED NOT NULL,
  `quality` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `tokens` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`source`, `quality`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `manastorm_coa_encounter_rewards` (`source`, `quality`, `tokens`) VALUES
(1, 2, 25),
(1, 3, 50),
(1, 4, 100),
(2, 0, 50);
