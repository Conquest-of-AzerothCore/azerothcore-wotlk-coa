--
DROP TABLE IF EXISTS `coa_pet_follower`;
CREATE TABLE `coa_pet_follower` (
  `guid` INT UNSIGNED NOT NULL,
  `species` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
