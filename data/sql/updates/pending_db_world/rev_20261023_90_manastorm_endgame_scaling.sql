CREATE TABLE IF NOT EXISTS `manastorm_Endgame_scaling_curve` (
  `depth` INT UNSIGNED NOT NULL,
  `health_multiplier` FLOAT NOT NULL DEFAULT 1,
  `global_damage_multiplier` FLOAT NOT NULL DEFAULT 1,
  `melee_multiplier` FLOAT NOT NULL DEFAULT 1,
  `spell_multiplier` FLOAT NOT NULL DEFAULT 1,
  PRIMARY KEY (`depth`)
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

-- Seed missing rows only: retain later endgame tuning and never multiply an existing endgame value again.
INSERT IGNORE INTO `manastorm_Endgame_scaling_curve`
  (`depth`, `health_multiplier`, `global_damage_multiplier`, `melee_multiplier`, `spell_multiplier`)
SELECT `depth`, `health_multiplier`, `global_damage_multiplier` * 2, `melee_multiplier`, `spell_multiplier`
FROM `manastorm_scaling_curve`;

INSERT IGNORE INTO `manastorm_Endgame_group_scaling`
  (`min_members`, `max_members`, `health_multiplier`, `global_damage_multiplier`, `melee_multiplier`, `spell_multiplier`, `enabled`)
SELECT `min_members`, `max_members`, `health_multiplier`, `global_damage_multiplier`, `melee_multiplier`, `spell_multiplier`, `enabled`
FROM `manastorm_group_scaling`;
