DROP TABLE IF EXISTS `coa_pet_standin`;
CREATE TABLE `coa_pet_standin` (
  `species` INT UNSIGNED NOT NULL,
  `entry` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`species`),
  UNIQUE KEY `entry` (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
