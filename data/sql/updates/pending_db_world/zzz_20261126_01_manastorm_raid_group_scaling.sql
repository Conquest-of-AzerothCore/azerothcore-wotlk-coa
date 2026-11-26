-- Manastorm raid-size scaling (6 to 15 members) for normal and endgame runs.
CREATE TABLE IF NOT EXISTS `manastorm_group_scaling` (
  `min_members` TINYINT UNSIGNED NOT NULL,
  `max_members` TINYINT UNSIGNED NOT NULL,
  `health_multiplier` FLOAT NOT NULL DEFAULT 1,
  `global_damage_multiplier` FLOAT NOT NULL DEFAULT 1,
  `melee_multiplier` FLOAT NOT NULL DEFAULT 1,
  `spell_multiplier` FLOAT NOT NULL DEFAULT 1,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`min_members`, `max_members`),
  KEY `idx_group_scaling_enabled` (`enabled`, `min_members`, `max_members`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_Endgame_group_scaling` (
  `min_members` TINYINT UNSIGNED NOT NULL,
  `max_members` TINYINT UNSIGNED NOT NULL,
  `health_multiplier` FLOAT NOT NULL DEFAULT 1,
  `global_damage_multiplier` FLOAT NOT NULL DEFAULT 1,
  `melee_multiplier` FLOAT NOT NULL DEFAULT 1,
  `spell_multiplier` FLOAT NOT NULL DEFAULT 1,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`min_members`, `max_members`),
  KEY `idx_endgame_group_scaling_enabled` (`enabled`, `min_members`, `max_members`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `manastorm_group_scaling` WHERE `min_members` BETWEEN 6 AND 15 AND `max_members` BETWEEN 6 AND 15;
INSERT INTO `manastorm_group_scaling` (`min_members`, `max_members`, `health_multiplier`, `global_damage_multiplier`, `melee_multiplier`, `spell_multiplier`, `enabled`) VALUES
(6, 6, 4.00, 1.25, 1, 1, 1),
(7, 7, 4.60, 1.30, 1, 1, 1),
(8, 8, 5.20, 1.35, 1, 1, 1),
(9, 9, 5.80, 1.40, 1, 1, 1),
(10, 10, 6.40, 1.45, 1, 1, 1),
(11, 11, 7.00, 1.50, 1, 1, 1),
(12, 12, 7.60, 1.55, 1, 1, 1),
(13, 13, 8.20, 1.60, 1, 1, 1),
(14, 14, 8.80, 1.65, 1, 1, 1),
(15, 15, 9.40, 1.70, 1, 1, 1);

DELETE FROM `manastorm_Endgame_group_scaling` WHERE `min_members` BETWEEN 6 AND 15 AND `max_members` BETWEEN 6 AND 15;
INSERT INTO `manastorm_Endgame_group_scaling` (`min_members`, `max_members`, `health_multiplier`, `global_damage_multiplier`, `melee_multiplier`, `spell_multiplier`, `enabled`) VALUES
(6, 6, 4.00, 1.75, 1, 1, 1),
(7, 7, 4.60, 1.90, 1, 1, 1),
(8, 8, 5.20, 2.05, 1, 1, 1),
(9, 9, 5.80, 2.20, 1, 1, 1),
(10, 10, 6.40, 2.35, 1, 1, 1),
(11, 11, 7.00, 2.50, 1, 1, 1),
(12, 12, 7.60, 2.65, 1, 1, 1),
(13, 13, 8.20, 2.80, 1, 1, 1),
(14, 14, 8.80, 2.95, 1, 1, 1),
(15, 15, 9.40, 3.10, 1, 1, 1);
