-- Optional Manastorm member-count scaling layer.
--
-- The existing manastorm_scaling_curve remains the generic Endless DEPTH
-- curve. This table multiplies that result by a member-count profile.
--
-- Authoring examples (do not uncomment blindly):
--
-- One generic profile for every legal Manastorm size:
-- INSERT INTO `manastorm_group_scaling`
--   (`min_members`, `max_members`, `health_multiplier`,
--    `global_damage_multiplier`, `melee_multiplier`,
--    `spell_multiplier`, `enabled`)
-- VALUES (1, 15, 1.0, 1.0, 1.0, 1.0, 1);
--
-- Solo / Duo / Trio / Group buckets:
--   1-1, 2-2, 3-3, 4-15
--
-- Exact recovered tuning can later use fifteen non-overlapping rows:
--   1-1, 2-2, ... 15-15
--
-- No gameplay values are inserted by this migration because the exact
-- native group multipliers have not yet been decoded with sufficient
-- confidence.

CREATE TABLE IF NOT EXISTS `manastorm_group_scaling` (
  `min_members` TINYINT UNSIGNED NOT NULL,
  `max_members` TINYINT UNSIGNED NOT NULL,
  `health_multiplier` FLOAT NOT NULL DEFAULT 1,
  `global_damage_multiplier` FLOAT NOT NULL DEFAULT 1,
  `melee_multiplier` FLOAT NOT NULL DEFAULT 1,
  `spell_multiplier` FLOAT NOT NULL DEFAULT 1,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`min_members`,`max_members`),
  KEY `idx_group_scaling_enabled` (`enabled`,`min_members`,`max_members`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
