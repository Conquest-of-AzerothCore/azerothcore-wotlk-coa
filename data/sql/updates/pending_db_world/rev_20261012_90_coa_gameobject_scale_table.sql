-- Per-spawn scale for game objects, set in game with .goscale and applied when the spawn loads.
CREATE TABLE IF NOT EXISTS `gameobject_scale` (
  `guid` INT UNSIGNED NOT NULL,
  `scale` FLOAT NOT NULL DEFAULT 1,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
