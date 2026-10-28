-- Per-spawn scale for game objects, applied whenever the spawn enters the world.
CREATE TABLE IF NOT EXISTS `gameobject_scale` (
  `guid` INT UNSIGNED NOT NULL,
  `scale` FLOAT NOT NULL DEFAULT 1,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELETE FROM `command` WHERE `name` = 'gobject set scale';
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('gobject set scale', 2, 'Syntax: .gobject set scale #guid #scale\nStores #scale (0.1 to 10) for the game object spawn #guid and respawns its loaded copies at that size.');
