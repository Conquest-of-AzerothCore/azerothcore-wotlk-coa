-- Project Ascension custom class identities used by the copied client.
CREATE TABLE IF NOT EXISTS `ascension_custom_class` (
    `class` TINYINT UNSIGNED NOT NULL,
    `name` VARCHAR(32) NOT NULL,
    `client_name` VARCHAR(32) NOT NULL,
    `fallback_class` TINYINT UNSIGNED NOT NULL,
    `power_type` TINYINT UNSIGNED NOT NULL,
    `primary_stat` VARCHAR(16) NOT NULL,
    PRIMARY KEY (`class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELETE FROM `ascension_custom_class`
WHERE `class` BETWEEN 12 AND 32;

INSERT INTO `ascension_custom_class`
    (`class`, `name`, `client_name`, `fallback_class`, `power_type`, `primary_stat`)
VALUES
    (12, 'Barbarian', 'Barbarian', 4, 3, 'Agility'),
    (13, 'Witch Doctor', 'Witch Doctor', 7, 0, 'Intellect'),
    (14, 'Demon Hunter', 'Felsworn', 4, 3, 'Agility'),
    (15, 'Witch Hunter', 'Witch Hunter', 3, 0, 'Agility'),
    (16, 'Stormbringer', 'Stormbringer', 7, 0, 'Intellect'),
    (17, 'Fleshwarden', 'Knight of Xoroth', 1, 1, 'Strength'),
    (18, 'Guardian', 'Guardian', 1, 3, 'Strength'),
    (19, 'Monk', 'Templar', 4, 3, 'Agility'),
    (20, 'Son of Arugal', 'Bloodmage', 11, 1, 'Agility'),
    (21, 'Ranger', 'Ranger', 3, 2, 'Agility'),
    (22, 'Chronomancer', 'Chronomancer', 5, 0, 'Spirit'),
    (23, 'Necromancer', 'Necromancer', 9, 6, 'Intellect'),
    (24, 'Pyromancer', 'Pyromancer', 8, 0, 'Intellect'),
    (25, 'Cultist', 'Cultist', 2, 0, 'Strength'),
    (26, 'Starcaller', 'Starcaller', 11, 3, 'Intellect'),
    (27, 'Sun Cleric', 'Sun Cleric', 5, 0, 'Intellect'),
    (28, 'Tinker', 'Tinker', 3, 0, 'Agility'),
    (29, 'Prophet', 'Venomancer', 7, 0, 'Intellect'),
    (30, 'Reaper', 'Reaper', 4, 6, 'Agility'),
    (31, 'Wildwalker', 'Primalist', 11, 0, 'Agility'),
    (32, 'Spirit Mage', 'Runemaster', 7, 0, 'Intellect');

CREATE TABLE IF NOT EXISTS `ascension_custom_class_race` (
    `class` TINYINT UNSIGNED NOT NULL,
    `race` TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`class`, `race`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELETE FROM `ascension_custom_class_race`
WHERE `class` BETWEEN 12 AND 32;

INSERT INTO `ascension_custom_class_race` (`class`, `race`)
VALUES
    (12, 1), (12, 2), (12, 3), (12, 5), (12, 6), (12, 8),
    (13, 1), (13, 2), (13, 8),
    (14, 2), (14, 4), (14, 10), (14, 11),
    (15, 1), (15, 4), (15, 5),
    (16, 1), (16, 2), (16, 3), (16, 5), (16, 6), (16, 7), (16, 8), (16, 10), (16, 11),
    (17, 2), (17, 10), (17, 11),
    (18, 1), (18, 2), (18, 3), (18, 4), (18, 5), (18, 6), (18, 8), (18, 10), (18, 11),
    (19, 1), (19, 3), (19, 5), (19, 10), (19, 11),
    (20, 1), (20, 4), (20, 5), (20, 8), (20, 10),
    (21, 1), (21, 2), (21, 3), (21, 4), (21, 5), (21, 7), (21, 8), (21, 10),
    (22, 1), (22, 7), (22, 10), (22, 11),
    (23, 1), (23, 2), (23, 5), (23, 7), (23, 8), (23, 10), (23, 11),
    (24, 1), (24, 2), (24, 3), (24, 4), (24, 5), (24, 6), (24, 7), (24, 8), (24, 10), (24, 11),
    (25, 1), (25, 2), (25, 3), (25, 4), (25, 5), (25, 6), (25, 7), (25, 8), (25, 10), (25, 11),
    (26, 4), (26, 6), (26, 10), (26, 11),
    (27, 1), (27, 3), (27, 6), (27, 10),
    (28, 1), (28, 2), (28, 3), (28, 5), (28, 7), (28, 10), (28, 11),
    (29, 4), (29, 5), (29, 8),
    (30, 1), (30, 5), (30, 8), (30, 10), (30, 11),
    (31, 2), (31, 3), (31, 4), (31, 6), (31, 8), (31, 11),
    (32, 1), (32, 2), (32, 3), (32, 4), (32, 5), (32, 6), (32, 7), (32, 10), (32, 11);

-- Custom classes start at their race's normal non-hero location.
DELETE FROM `playercreateinfo`
WHERE `class` BETWEEN 12 AND 32;

INSERT INTO `playercreateinfo`
    (`race`, `class`, `map`, `zone`, `position_x`, `position_y`, `position_z`, `orientation`)
SELECT
    `allowed`.`race`,
    `allowed`.`class`,
    `source`.`map`,
    `source`.`zone`,
    `source`.`position_x`,
    `source`.`position_y`,
    `source`.`position_z`,
    `source`.`orientation`
FROM `ascension_custom_class_race` AS `allowed`
INNER JOIN (
    SELECT `race`, MIN(`class`) AS `class`
    FROM `playercreateinfo`
    WHERE `class` BETWEEN 1 AND 11
      AND `class` <> 6
    GROUP BY `race`
) AS `base` ON `base`.`race` = `allowed`.`race`
INNER JOIN `playercreateinfo` AS `source`
    ON `source`.`race` = `base`.`race`
   AND `source`.`class` = `base`.`class`;

-- Until the proprietary per-level server formulas are recovered, use the
-- closest legacy class curve. The real class ID and DBC combat curves remain
-- intact, so this does not collapse custom characters back to stock classes.
DELETE FROM `player_class_stats`
WHERE `Class` BETWEEN 12 AND 32;

INSERT INTO `player_class_stats`
    (`Class`, `Level`, `BaseHP`, `BaseMana`, `Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`)
SELECT
    `custom`.`class`,
    `stats`.`Level`,
    `stats`.`BaseHP`,
    `stats`.`BaseMana`,
    `stats`.`Strength`,
    `stats`.`Agility`,
    `stats`.`Stamina`,
    `stats`.`Intellect`,
    `stats`.`Spirit`
FROM `ascension_custom_class` AS `custom`
INNER JOIN `player_class_stats` AS `stats`
    ON `stats`.`Class` = `custom`.`fallback_class`;

-- Every custom character needs the basic Attack action even before its
-- Advancement build grants class-specific abilities.
DELETE FROM `playercreateinfo_action`
WHERE `class` BETWEEN 12 AND 32
  AND `button` = 0;

INSERT INTO `playercreateinfo_action`
    (`race`, `class`, `button`, `action`, `type`)
SELECT `race`, `class`, 0, 6603, 0
FROM `ascension_custom_class_race`;
