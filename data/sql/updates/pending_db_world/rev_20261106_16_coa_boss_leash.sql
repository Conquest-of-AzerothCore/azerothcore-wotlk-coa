-- Boss leashes for Heroic and Mythic dungeons (#11389): a boss in combat that leaves its area evades. The area is the
-- polygon of its leash points when it has 3 or more, otherwise a circle of `radius` yards around its spawn point.
-- Game masters set them in game with .leash point / undo / radius / clear / show.
CREATE TABLE IF NOT EXISTS `coa_boss_leash` (
  `entry` INT UNSIGNED NOT NULL,
  `radius` FLOAT NOT NULL DEFAULT 0,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `coa_boss_leash_point` (
  `entry` INT UNSIGNED NOT NULL,
  `point` TINYINT UNSIGNED NOT NULL,
  `x` FLOAT NOT NULL,
  `y` FLOAT NOT NULL,
  `z` FLOAT NOT NULL,
  PRIMARY KEY (`entry`, `point`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELETE FROM `command` WHERE `name` IN ('leash point', 'leash undo', 'leash radius', 'leash clear', 'leash show');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('leash point', 2, 'Syntax: .leash point [#entry]\nAdds your position as the next corner of the boss''s leash area. The boss is #entry, else your selected creature, else the boss you edited last. From 3 points on, the boss evades on Heroic and Mythic when it leaves the area.'),
('leash undo', 2, 'Syntax: .leash undo [#entry]\nRemoves the last corner of the boss''s leash area.'),
('leash radius', 2, 'Syntax: .leash radius #yards [#entry]\nSets a leash circle of #yards around the boss''s spawn point, used while it has fewer than 3 corners. 0 turns it off.'),
('leash clear', 2, 'Syntax: .leash clear [#entry]\nRemoves the boss''s leash.'),
('leash show', 2, 'Syntax: .leash show [#entry]\nLists the boss''s leash, marks its corners for a minute and says whether you stand inside.');
