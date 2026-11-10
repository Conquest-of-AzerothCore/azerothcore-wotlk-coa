CREATE TABLE IF NOT EXISTS `manastorm_coa_encounter_rewards` (
  `source` TINYINT UNSIGNED NOT NULL,
  `quality` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `tokens` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`source`, `quality`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELETE FROM `manastorm_coa_encounter_rewards`
WHERE (`source` = 1 AND `quality` = 2 AND `tokens` = 25)
    OR (`source` = 1 AND `quality` = 3 AND `tokens` = 50)
    OR (`source` = 1 AND `quality` = 4 AND `tokens` = 100)
    OR (`source` = 2 AND `quality` = 0 AND `tokens` = 50);

INSERT IGNORE INTO `manastorm_coa_encounter_rewards` (`source`, `quality`, `tokens`) VALUES
(1, 2, 25),
(1, 3, 50),
(1, 4, 100),
(2, 0, 50);
