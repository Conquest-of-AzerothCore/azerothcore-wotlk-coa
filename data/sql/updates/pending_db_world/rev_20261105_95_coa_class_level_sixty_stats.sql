-- Level-60 base stats, base health and base mana of the Ascension classes from coa.bisbeard.com
-- (realmDataCoa, source "coa-text", stamina and base health multiplied by 1.2), verified by the project 2026-11-03.
-- Levels 2-59 stretch each fallback class's curve between the class's level-one row and its level-60 target;
-- levels 61-80 keep the fallback gains above 60. Level one stays as calibrated in rev_20260903_01.
-- The curve goes to ascension_class_stats and player_class_stats keeps the stock rows;
-- the server uses it only with CoA.ClassLevelSixtyStats.Enable = 1 in coa.conf (default 0), applied on a restart.
CREATE TABLE IF NOT EXISTS `ascension_class_stats` (
  `Class` tinyint unsigned NOT NULL,
  `Level` tinyint unsigned NOT NULL,
  `BaseHP` int unsigned NOT NULL DEFAULT '1',
  `BaseMana` int unsigned NOT NULL DEFAULT '1',
  `Strength` int unsigned NOT NULL DEFAULT '0',
  `Agility` int unsigned NOT NULL DEFAULT '0',
  `Stamina` int unsigned NOT NULL DEFAULT '0',
  `Intellect` int unsigned NOT NULL DEFAULT '0',
  `Spirit` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`Class`, `Level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Ascension class level stats used instead of player_class_stats while CoA.ClassLevelSixtyStats.Enable is 1.';

CREATE TABLE IF NOT EXISTS `ascension_race_class_stats` (
  `Race` tinyint unsigned NOT NULL,
  `Class` tinyint unsigned NOT NULL,
  `Level` tinyint unsigned NOT NULL,
  `Strength` smallint NOT NULL DEFAULT 0,
  `Agility` smallint NOT NULL DEFAULT 0,
  `Stamina` smallint NOT NULL DEFAULT 0,
  `Intellect` smallint NOT NULL DEFAULT 0,
  `Spirit` smallint NOT NULL DEFAULT 0,
  PRIMARY KEY (`Race`, `Class`, `Level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Per race and class stat adjustment added to player_class_stats plus player_race_stats.';

DROP TEMPORARY TABLE IF EXISTS `_coa_level_sixty_class`;
CREATE TEMPORARY TABLE `_coa_level_sixty_class` (
  `Class` tinyint unsigned NOT NULL,
  `BaseHP` int NOT NULL,
  `BaseMana` int NOT NULL,
  `Strength` int NOT NULL,
  `Agility` int NOT NULL,
  `Stamina` int NOT NULL,
  `Intellect` int NOT NULL,
  `Spirit` int NOT NULL,
  PRIMARY KEY (`Class`)
) ENGINE=InnoDB;
DELETE FROM `_coa_level_sixty_class`;
INSERT INTO `_coa_level_sixty_class` (`Class`, `BaseHP`, `BaseMana`,
    `Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`) VALUES
(12, 3752, 0, 99, 98, 90, 51, 67),
(13, 3128, 1538, 54, 82, 86, 79, 106),
(14, 3440, 0, 68, 93, 93, 75, 78),
(15, 3440, 2064, 75, 94, 91, 71, 75),
(16, 2925, 1456, 55, 57, 73, 119, 103),
(17, 4220, 0, 117, 69, 99, 66, 55),
(18, 3752, 0, 99, 76, 112, 59, 62),
(19, 4220, 0, 83, 92, 96, 63, 72),
(20, 3385, 0, 71, 75, 102, 73, 87),
(21, 2972, 0, 80, 110, 91, 65, 60),
(22, 3307, 1651, 54, 61, 74, 105, 115),
(23, 3463, 1648, 69, 50, 91, 109, 91),
(24, 2956, 1456, 51, 63, 78, 109, 108),
(25, 3502, 1814, 92, 66, 99, 78, 72),
(26, 3151, 1824, 82, 71, 92, 104, 57),
(27, 3463, 1814, 94, 55, 97, 80, 84),
(28, 3229, 1824, 74, 94, 87, 91, 59),
(29, 2995, 1824, 63, 78, 86, 91, 90),
(30, 4196, 0, 95, 70, 100, 67, 76),
(31, 3697, 1824, 89, 73, 90, 86, 67),
(32, 2917, 1361, 60, 88, 87, 96, 75);

DROP TEMPORARY TABLE IF EXISTS `_coa_level_sixty_race_class`;
CREATE TEMPORARY TABLE `_coa_level_sixty_race_class` (
  `Race` tinyint unsigned NOT NULL,
  `Class` tinyint unsigned NOT NULL,
  `Strength` int NOT NULL,
  `Agility` int NOT NULL,
  `Stamina` int NOT NULL,
  `Intellect` int NOT NULL,
  `Spirit` int NOT NULL,
  PRIMARY KEY (`Race`, `Class`)
) ENGINE=InnoDB;
DELETE FROM `_coa_level_sixty_race_class`;
INSERT INTO `_coa_level_sixty_race_class` (`Race`, `Class`,
    `Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`) VALUES
(1, 12, 99, 98, 90, 51, 67),
(2, 12, 106, 101, 98, 47, 60),
(3, 12, 104, 94, 98, 49, 63),
(4, 12, 102, 106, 92, 49, 61),
(5, 12, 94, 106, 92, 50, 65),
(6, 12, 109, 93, 99, 47, 63),
(7, 12, 93, 103, 87, 54, 65),
(8, 12, 101, 106, 93, 47, 64),
(10, 12, 96, 102, 93, 54, 60),
(11, 12, 103, 95, 94, 51, 63),
(1, 13, 54, 82, 86, 79, 106),
(2, 13, 58, 85, 94, 73, 96),
(3, 13, 57, 79, 94, 76, 100),
(4, 13, 56, 88, 88, 77, 97),
(5, 13, 52, 88, 88, 79, 103),
(6, 13, 59, 78, 96, 73, 100),
(7, 13, 51, 87, 84, 85, 103),
(8, 13, 55, 88, 90, 73, 102),
(10, 13, 53, 86, 90, 84, 96),
(11, 13, 57, 80, 91, 79, 100),
(1, 14, 68, 93, 93, 75, 78),
(2, 14, 72, 96, 102, 69, 71),
(3, 14, 71, 89, 102, 72, 74),
(4, 14, 70, 100, 94, 72, 72),
(5, 14, 64, 100, 94, 74, 76),
(6, 14, 74, 88, 103, 69, 74),
(7, 14, 64, 98, 90, 80, 76),
(8, 14, 69, 100, 96, 69, 75),
(10, 14, 66, 97, 96, 79, 71),
(11, 14, 70, 90, 98, 75, 74),
(1, 15, 75, 94, 91, 71, 75),
(2, 15, 79, 97, 99, 66, 68),
(3, 15, 78, 90, 99, 69, 71),
(4, 15, 77, 101, 93, 69, 69),
(5, 15, 71, 101, 93, 71, 73),
(6, 15, 81, 89, 100, 66, 71),
(7, 15, 70, 99, 88, 76, 73),
(8, 15, 76, 101, 93, 66, 72),
(10, 15, 72, 98, 93, 76, 68),
(11, 15, 78, 91, 96, 71, 71),
(1, 16, 55, 57, 73, 119, 103),
(2, 16, 59, 59, 80, 110, 93),
(3, 16, 58, 55, 80, 114, 97),
(4, 16, 57, 61, 74, 115, 94),
(5, 16, 52, 61, 74, 118, 100),
(6, 16, 60, 54, 80, 110, 97),
(7, 16, 52, 60, 70, 127, 100),
(8, 16, 56, 61, 75, 110, 99),
(10, 16, 54, 59, 75, 126, 93),
(11, 16, 57, 55, 76, 119, 97),
(1, 17, 117, 69, 99, 66, 55),
(2, 17, 124, 71, 109, 61, 50),
(3, 17, 122, 66, 109, 63, 52),
(4, 17, 120, 74, 102, 64, 50),
(5, 17, 111, 74, 102, 65, 53),
(6, 17, 127, 66, 110, 61, 52),
(7, 17, 110, 73, 96, 70, 53),
(8, 17, 119, 74, 102, 61, 53),
(10, 17, 113, 72, 102, 70, 50),
(11, 17, 121, 67, 104, 66, 52),
(1, 18, 99, 76, 112, 59, 62),
(2, 18, 106, 78, 123, 54, 56),
(3, 18, 104, 73, 123, 56, 58),
(4, 18, 102, 82, 115, 57, 56),
(5, 18, 94, 82, 115, 58, 60),
(6, 18, 109, 72, 124, 54, 58),
(7, 18, 93, 80, 109, 63, 60),
(8, 18, 101, 82, 116, 54, 59),
(10, 18, 96, 79, 116, 62, 56),
(11, 18, 103, 74, 118, 59, 58),
(1, 19, 83, 92, 96, 63, 72),
(2, 19, 88, 95, 104, 58, 66),
(3, 19, 87, 89, 104, 61, 68),
(4, 19, 86, 99, 98, 62, 66),
(5, 19, 79, 99, 98, 63, 70),
(6, 19, 91, 88, 105, 58, 68),
(7, 19, 78, 97, 92, 68, 70),
(8, 19, 85, 99, 98, 58, 70),
(10, 19, 81, 96, 98, 67, 66),
(11, 19, 87, 89, 100, 63, 68),
(1, 20, 71, 75, 102, 73, 87),
(2, 20, 76, 78, 111, 67, 79),
(3, 20, 75, 72, 111, 70, 82),
(4, 20, 74, 81, 104, 71, 80),
(5, 20, 68, 81, 104, 72, 85),
(6, 20, 78, 72, 112, 67, 82),
(7, 20, 67, 79, 98, 78, 85),
(8, 20, 73, 81, 105, 67, 84),
(10, 20, 69, 78, 105, 77, 79),
(11, 20, 74, 73, 108, 73, 82),
(1, 21, 80, 110, 91, 65, 60),
(2, 21, 85, 113, 99, 60, 54),
(3, 21, 84, 106, 99, 62, 57),
(4, 21, 82, 118, 93, 63, 55),
(5, 21, 76, 118, 93, 64, 58),
(6, 21, 87, 104, 100, 60, 57),
(7, 21, 75, 116, 88, 70, 58),
(8, 21, 82, 118, 93, 60, 58),
(10, 21, 78, 115, 93, 69, 54),
(11, 21, 83, 107, 96, 65, 57),
(1, 22, 54, 61, 74, 105, 115),
(2, 22, 57, 63, 81, 96, 104),
(3, 22, 56, 58, 81, 101, 108),
(4, 22, 55, 65, 75, 102, 105),
(5, 22, 51, 65, 75, 104, 112),
(6, 22, 58, 58, 81, 96, 108),
(7, 22, 50, 64, 72, 112, 112),
(8, 22, 55, 65, 76, 96, 110),
(10, 22, 52, 63, 76, 111, 104),
(11, 22, 56, 59, 78, 105, 108),
(1, 23, 69, 50, 91, 109, 91),
(2, 23, 73, 52, 99, 100, 82),
(3, 23, 73, 48, 99, 104, 86),
(4, 23, 71, 54, 93, 105, 83),
(5, 23, 66, 54, 93, 108, 88),
(6, 23, 75, 47, 100, 100, 86),
(7, 23, 65, 53, 88, 116, 88),
(8, 23, 71, 54, 93, 100, 87),
(10, 23, 67, 52, 93, 115, 82),
(11, 23, 72, 48, 96, 109, 86),
(1, 24, 51, 63, 78, 109, 108),
(2, 24, 54, 65, 85, 100, 98),
(3, 24, 53, 61, 85, 104, 102),
(4, 24, 52, 68, 79, 105, 99),
(5, 24, 48, 68, 79, 108, 105),
(6, 24, 55, 60, 86, 100, 102),
(7, 24, 47, 66, 75, 116, 105),
(8, 24, 52, 68, 80, 100, 104),
(10, 24, 49, 66, 80, 115, 98),
(11, 24, 53, 61, 81, 109, 102),
(1, 25, 92, 66, 99, 78, 72),
(2, 25, 98, 68, 109, 72, 65),
(3, 25, 97, 63, 109, 75, 68),
(4, 25, 95, 71, 102, 76, 65),
(5, 25, 88, 71, 102, 78, 70),
(6, 25, 101, 63, 110, 72, 68),
(7, 25, 87, 70, 96, 84, 70),
(8, 25, 94, 71, 102, 72, 69),
(10, 25, 90, 69, 102, 83, 65),
(11, 25, 96, 64, 104, 78, 68),
(1, 26, 82, 71, 92, 104, 57),
(2, 26, 87, 73, 100, 96, 52),
(3, 26, 86, 68, 100, 100, 54),
(4, 26, 84, 76, 93, 101, 53),
(5, 26, 77, 76, 93, 103, 56),
(6, 26, 89, 67, 102, 96, 54),
(7, 26, 77, 74, 88, 111, 56),
(8, 26, 83, 76, 94, 96, 55),
(10, 26, 79, 74, 94, 110, 52),
(11, 26, 85, 69, 97, 104, 54),
(1, 27, 94, 55, 97, 80, 84),
(2, 27, 100, 56, 105, 74, 76),
(3, 27, 99, 52, 105, 77, 79),
(4, 27, 97, 59, 98, 78, 77),
(5, 27, 89, 59, 98, 79, 82),
(6, 27, 103, 52, 106, 74, 79),
(7, 27, 88, 57, 93, 86, 82),
(8, 27, 96, 59, 99, 74, 81),
(10, 27, 91, 57, 99, 85, 76),
(11, 27, 98, 53, 102, 80, 79),
(1, 28, 74, 94, 87, 91, 59),
(2, 28, 78, 97, 96, 84, 54),
(3, 28, 78, 90, 96, 88, 56),
(4, 28, 76, 101, 90, 88, 54),
(5, 28, 70, 101, 90, 90, 57),
(6, 28, 81, 89, 97, 84, 56),
(7, 28, 69, 99, 85, 97, 57),
(8, 28, 75, 101, 90, 84, 57),
(10, 28, 72, 98, 90, 97, 54),
(11, 28, 77, 91, 92, 91, 56),
(1, 29, 63, 78, 86, 91, 90),
(2, 29, 67, 80, 94, 84, 81),
(3, 29, 66, 75, 94, 88, 85),
(4, 29, 65, 83, 88, 88, 82),
(5, 29, 60, 83, 88, 90, 87),
(6, 29, 69, 74, 96, 84, 85),
(7, 29, 59, 82, 84, 97, 87),
(8, 29, 64, 83, 90, 84, 86),
(10, 29, 61, 81, 90, 97, 81),
(11, 29, 65, 75, 91, 91, 85),
(1, 30, 95, 70, 100, 67, 76),
(2, 30, 101, 72, 109, 62, 69),
(3, 30, 100, 67, 109, 65, 71),
(4, 30, 98, 75, 102, 65, 69),
(5, 30, 90, 75, 102, 67, 74),
(6, 30, 103, 66, 110, 62, 71),
(7, 30, 89, 74, 97, 72, 74),
(8, 30, 97, 75, 103, 62, 73),
(10, 30, 92, 73, 103, 71, 69),
(11, 30, 99, 68, 105, 67, 71),
(1, 31, 89, 73, 90, 86, 67),
(2, 31, 95, 75, 98, 80, 61),
(3, 31, 94, 70, 98, 83, 64),
(4, 31, 92, 78, 92, 84, 62),
(5, 31, 85, 78, 92, 86, 65),
(6, 31, 97, 69, 99, 80, 64),
(7, 31, 84, 77, 87, 92, 65),
(8, 31, 91, 78, 93, 80, 65),
(10, 31, 87, 76, 93, 92, 61),
(11, 31, 93, 71, 94, 86, 64),
(1, 32, 60, 88, 87, 96, 75),
(2, 32, 63, 91, 96, 88, 68),
(3, 32, 63, 85, 96, 92, 71),
(4, 32, 62, 95, 90, 93, 69),
(5, 32, 57, 95, 90, 95, 73),
(6, 32, 65, 84, 97, 88, 71),
(7, 32, 56, 93, 85, 103, 73),
(8, 32, 61, 95, 90, 88, 72),
(10, 32, 58, 92, 90, 102, 68),
(11, 32, 62, 86, 92, 96, 71);

DROP TEMPORARY TABLE IF EXISTS `_coa_level_sixty_progress`;
CREATE TEMPORARY TABLE `_coa_level_sixty_progress` ENGINE=InnoDB AS
WITH `donor` AS (
    SELECT `Class`, `Level`,
        CAST(`BaseHP` AS SIGNED) AS `BaseHP`,
        CAST(`BaseMana` AS SIGNED) AS `BaseMana`,
        CAST(`Strength` AS SIGNED) AS `Strength`,
        CAST(`Agility` AS SIGNED) AS `Agility`,
        CAST(`Stamina` AS SIGNED) AS `Stamina`,
        CAST(`Intellect` AS SIGNED) AS `Intellect`,
        CAST(`Spirit` AS SIGNED) AS `Spirit`
    FROM `player_class_stats` WHERE `Class` BETWEEN 1 AND 11)
SELECT `custom`.`class` AS `Class`, `curve`.`Level`,
    CAST(`start`.`BaseHP` AS SIGNED) AS `BaseHPStart`,
    `curve`.`BaseHP` - `first`.`BaseHP` AS `BaseHPGain`,
    `cap`.`BaseHP` - `first`.`BaseHP` AS `BaseHPSpan`,
    `curve`.`BaseHP` - `cap`.`BaseHP` AS `BaseHPOver`,
    CAST(`start`.`BaseMana` AS SIGNED) AS `BaseManaStart`,
    `curve`.`BaseMana` - `first`.`BaseMana` AS `BaseManaGain`,
    `cap`.`BaseMana` - `first`.`BaseMana` AS `BaseManaSpan`,
    `curve`.`BaseMana` - `cap`.`BaseMana` AS `BaseManaOver`,
    CAST(`start`.`Strength` AS SIGNED) AS `StrengthStart`,
    `curve`.`Strength` - `first`.`Strength` AS `StrengthGain`,
    `cap`.`Strength` - `first`.`Strength` AS `StrengthSpan`,
    `curve`.`Strength` - `cap`.`Strength` AS `StrengthOver`,
    CAST(`start`.`Agility` AS SIGNED) AS `AgilityStart`,
    `curve`.`Agility` - `first`.`Agility` AS `AgilityGain`,
    `cap`.`Agility` - `first`.`Agility` AS `AgilitySpan`,
    `curve`.`Agility` - `cap`.`Agility` AS `AgilityOver`,
    CAST(`start`.`Stamina` AS SIGNED) AS `StaminaStart`,
    `curve`.`Stamina` - `first`.`Stamina` AS `StaminaGain`,
    `cap`.`Stamina` - `first`.`Stamina` AS `StaminaSpan`,
    `curve`.`Stamina` - `cap`.`Stamina` AS `StaminaOver`,
    CAST(`start`.`Intellect` AS SIGNED) AS `IntellectStart`,
    `curve`.`Intellect` - `first`.`Intellect` AS `IntellectGain`,
    `cap`.`Intellect` - `first`.`Intellect` AS `IntellectSpan`,
    `curve`.`Intellect` - `cap`.`Intellect` AS `IntellectOver`,
    CAST(`start`.`Spirit` AS SIGNED) AS `SpiritStart`,
    `curve`.`Spirit` - `first`.`Spirit` AS `SpiritGain`,
    `cap`.`Spirit` - `first`.`Spirit` AS `SpiritSpan`,
    `curve`.`Spirit` - `cap`.`Spirit` AS `SpiritOver`
FROM `ascension_custom_class` AS `custom`
INNER JOIN `player_class_stats` AS `start` ON `start`.`Class` = `custom`.`class` AND `start`.`Level` = 1
INNER JOIN `donor` AS `first` ON `first`.`Class` = `custom`.`fallback_class` AND `first`.`Level` = 1
INNER JOIN `donor` AS `cap` ON `cap`.`Class` = `custom`.`fallback_class` AND `cap`.`Level` = 60
INNER JOIN `donor` AS `curve` ON `curve`.`Class` = `custom`.`fallback_class` AND `curve`.`Level` BETWEEN 2 AND 80
WHERE `custom`.`class` BETWEEN 12 AND 32;

DROP TEMPORARY TABLE IF EXISTS `_coa_level_sixty_class_curve`;
CREATE TEMPORARY TABLE `_coa_level_sixty_class_curve` ENGINE=InnoDB AS
SELECT `p`.`Class`, `p`.`Level`,
    IF(`p`.`Level` > 60, `t`.`BaseHP` + `p`.`BaseHPOver`,
        `p`.`BaseHPStart` + FLOOR(
            (2 * (`t`.`BaseHP` - `p`.`BaseHPStart`) * `p`.`BaseHPGain` + `p`.`BaseHPSpan`)
            / (2 * NULLIF(`p`.`BaseHPSpan`, 0)))) AS `BaseHP`,
    IF(`p`.`BaseManaStart` = 0, 0, IF(`p`.`Level` > 60, `t`.`BaseMana` + `p`.`BaseManaOver`,
        `p`.`BaseManaStart` + FLOOR(
            (2 * (`t`.`BaseMana` - `p`.`BaseManaStart`) * `p`.`BaseManaGain` + `p`.`BaseManaSpan`)
            / (2 * NULLIF(`p`.`BaseManaSpan`, 0))))) AS `BaseMana`,
    IF(`p`.`Level` > 60, `t`.`Strength` + `p`.`StrengthOver`,
        `p`.`StrengthStart` + FLOOR(
            (2 * (`t`.`Strength` - `p`.`StrengthStart`) * `p`.`StrengthGain` + `p`.`StrengthSpan`)
            / (2 * NULLIF(`p`.`StrengthSpan`, 0)))) AS `Strength`,
    IF(`p`.`Level` > 60, `t`.`Agility` + `p`.`AgilityOver`,
        `p`.`AgilityStart` + FLOOR(
            (2 * (`t`.`Agility` - `p`.`AgilityStart`) * `p`.`AgilityGain` + `p`.`AgilitySpan`)
            / (2 * NULLIF(`p`.`AgilitySpan`, 0)))) AS `Agility`,
    IF(`p`.`Level` > 60, `t`.`Stamina` + `p`.`StaminaOver`,
        `p`.`StaminaStart` + FLOOR(
            (2 * (`t`.`Stamina` - `p`.`StaminaStart`) * `p`.`StaminaGain` + `p`.`StaminaSpan`)
            / (2 * NULLIF(`p`.`StaminaSpan`, 0)))) AS `Stamina`,
    IF(`p`.`Level` > 60, `t`.`Intellect` + `p`.`IntellectOver`,
        `p`.`IntellectStart` + FLOOR(
            (2 * (`t`.`Intellect` - `p`.`IntellectStart`) * `p`.`IntellectGain` + `p`.`IntellectSpan`)
            / (2 * NULLIF(`p`.`IntellectSpan`, 0)))) AS `Intellect`,
    IF(`p`.`Level` > 60, `t`.`Spirit` + `p`.`SpiritOver`,
        `p`.`SpiritStart` + FLOOR(
            (2 * (`t`.`Spirit` - `p`.`SpiritStart`) * `p`.`SpiritGain` + `p`.`SpiritSpan`)
            / (2 * NULLIF(`p`.`SpiritSpan`, 0)))) AS `Spirit`
FROM `_coa_level_sixty_progress` AS `p`
INNER JOIN `_coa_level_sixty_class` AS `t` ON `t`.`Class` = `p`.`Class`;

DELETE FROM `ascension_class_stats` WHERE `Class` BETWEEN 12 AND 32 AND `Level` BETWEEN 2 AND 80;
INSERT INTO `ascension_class_stats` (`Class`, `Level`, `BaseHP`, `BaseMana`,
    `Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`)
SELECT `curve`.`Class`, `curve`.`Level`, `curve`.`BaseHP`, `curve`.`BaseMana`,
    `curve`.`Strength`, `curve`.`Agility`, `curve`.`Stamina`, `curve`.`Intellect`, `curve`.`Spirit`
FROM `_coa_level_sixty_class_curve` AS `curve`
INNER JOIN `player_class_stats` AS `stats` ON `stats`.`Class` = `curve`.`Class` AND `stats`.`Level` = `curve`.`Level`;

DROP TEMPORARY TABLE IF EXISTS `_coa_level_sixty_race_curve`;
CREATE TEMPORARY TABLE `_coa_level_sixty_race_curve` ENGINE=InnoDB AS
SELECT `t`.`Race`, `p`.`Class`, `p`.`Level`,
    IF(`p`.`Level` > 60, `t`.`Strength` - `c`.`Strength` - `r`.`Strength`,
        `p`.`StrengthStart` - `k`.`Strength` + FLOOR(
            (2 * (`t`.`Strength` - `r`.`Strength` - `p`.`StrengthStart`) * `p`.`StrengthGain` + `p`.`StrengthSpan`)
            / (2 * NULLIF(`p`.`StrengthSpan`, 0)))) AS `Strength`,
    IF(`p`.`Level` > 60, `t`.`Agility` - `c`.`Agility` - `r`.`Agility`,
        `p`.`AgilityStart` - `k`.`Agility` + FLOOR(
            (2 * (`t`.`Agility` - `r`.`Agility` - `p`.`AgilityStart`) * `p`.`AgilityGain` + `p`.`AgilitySpan`)
            / (2 * NULLIF(`p`.`AgilitySpan`, 0)))) AS `Agility`,
    IF(`p`.`Level` > 60, `t`.`Stamina` - `c`.`Stamina` - `r`.`Stamina`,
        `p`.`StaminaStart` - `k`.`Stamina` + FLOOR(
            (2 * (`t`.`Stamina` - `r`.`Stamina` - `p`.`StaminaStart`) * `p`.`StaminaGain` + `p`.`StaminaSpan`)
            / (2 * NULLIF(`p`.`StaminaSpan`, 0)))) AS `Stamina`,
    IF(`p`.`Level` > 60, `t`.`Intellect` - `c`.`Intellect` - `r`.`Intellect`,
        `p`.`IntellectStart` - `k`.`Intellect` + FLOOR(
            (2 * (`t`.`Intellect` - `r`.`Intellect` - `p`.`IntellectStart`) * `p`.`IntellectGain` + `p`.`IntellectSpan`)
            / (2 * NULLIF(`p`.`IntellectSpan`, 0)))) AS `Intellect`,
    IF(`p`.`Level` > 60, `t`.`Spirit` - `c`.`Spirit` - `r`.`Spirit`,
        `p`.`SpiritStart` - `k`.`Spirit` + FLOOR(
            (2 * (`t`.`Spirit` - `r`.`Spirit` - `p`.`SpiritStart`) * `p`.`SpiritGain` + `p`.`SpiritSpan`)
            / (2 * NULLIF(`p`.`SpiritSpan`, 0)))) AS `Spirit`
FROM `_coa_level_sixty_progress` AS `p`
INNER JOIN `_coa_level_sixty_race_class` AS `t` ON `t`.`Class` = `p`.`Class`
INNER JOIN `_coa_level_sixty_class` AS `c` ON `c`.`Class` = `p`.`Class`
INNER JOIN `_coa_level_sixty_class_curve` AS `k` ON `k`.`Class` = `p`.`Class` AND `k`.`Level` = `p`.`Level`
INNER JOIN `player_race_stats` AS `r` ON `r`.`Race` = `t`.`Race`;

DELETE FROM `ascension_race_class_stats` WHERE `Level` BETWEEN 2 AND 80
    AND (`Race`, `Class`) IN (SELECT `Race`, `Class` FROM `_coa_level_sixty_race_class`);
INSERT INTO `ascension_race_class_stats` (`Race`, `Class`, `Level`,
    `Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`)
SELECT `Race`, `Class`, `Level`, `Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`
FROM `_coa_level_sixty_race_curve`
WHERE `Strength` <> 0 OR `Agility` <> 0 OR `Stamina` <> 0 OR `Intellect` <> 0 OR `Spirit` <> 0;

DROP TEMPORARY TABLE `_coa_level_sixty_race_curve`;
DROP TEMPORARY TABLE `_coa_level_sixty_class_curve`;
DROP TEMPORARY TABLE `_coa_level_sixty_progress`;
DROP TEMPORARY TABLE `_coa_level_sixty_race_class`;
DROP TEMPORARY TABLE `_coa_level_sixty_class`;
