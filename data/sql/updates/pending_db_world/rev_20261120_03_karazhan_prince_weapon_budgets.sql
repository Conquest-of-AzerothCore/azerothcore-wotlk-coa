-- Prince weapon budgets use Naxx raid weapons and their existing difficulty curves.
-- Preserve each weapon's speed and stat types. Budgets are absolute for repeatable application.
CREATE TEMPORARY TABLE `_coa_karazhan_prince_weapons` (
    `entry` INT UNSIGNED PRIMARY KEY,
    `ItemLevel` INT NOT NULL,
    `RequiredLevel` INT NOT NULL,
    `dmg_min1` DECIMAL(10,3) NOT NULL,
    `dmg_max1` DECIMAL(10,3) NOT NULL,
    `stat_value1` INT NOT NULL,
    `stat_value2` INT NOT NULL,
    `stat_value3` INT NOT NULL,
    `stat_value4` INT NOT NULL
) ENGINE=InnoDB;

DELETE FROM `_coa_karazhan_prince_weapons`;
INSERT INTO `_coa_karazhan_prince_weapons` VALUES
(28770, 92, 60, 54.692, 87.559, 19, 19, 24, 130),
(328770, 96, 60, 55.347, 88.786, 20, 20, 26, 138),
(1328770, 101, 60, 56.279, 89.526, 21, 21, 28, 150),
(228770, 105, 60, 56.578, 90.564, 22, 22, 29, 158),
(28771, 92, 60, 79.125, 126.106, 16, 31, 14, 130),
(328771, 96, 60, 80.163, 127.759, 17, 34, 15, 138),
(1328771, 101, 60, 81.4, 129.731, 19, 36, 16, 150),
(228771, 105, 60, 82.474, 131.442, 19, 38, 17, 158),
(28772, 92, 60, 139.901, 258.654, 19, 34, 0, 0),
(328772, 96, 60, 143.263, 264.918, 19, 37, 0, 0),
(1328772, 101, 60, 147.15, 271.356, 22, 39, 0, 0),
(228772, 105, 60, 150.199, 277.052, 22, 42, 0, 0),
(28773, 92, 60, 278.152, 390.704, 46, 41, 24, 0),
(328773, 96, 60, 285.328, 400.783, 49, 44, 26, 0),
(1328773, 101, 60, 293.24, 411.896, 53, 47, 28, 0),
(228773, 105, 60, 299.569, 420.786, 56, 51, 30, 0);

UPDATE `item_template` AS `item`
JOIN `_coa_karazhan_prince_weapons` AS `budget` ON `budget`.`entry` = `item`.`entry`
SET
    `item`.`ItemLevel` = `budget`.`ItemLevel`,
    `item`.`RequiredLevel` = `budget`.`RequiredLevel`,
    `item`.`dmg_min1` = `budget`.`dmg_min1`,
    `item`.`dmg_max1` = `budget`.`dmg_max1`,
    `item`.`stat_value1` = `budget`.`stat_value1`,
    `item`.`stat_value2` = `budget`.`stat_value2`,
    `item`.`stat_value3` = `budget`.`stat_value3`,
    `item`.`stat_value4` = `budget`.`stat_value4`;

DROP TEMPORARY TABLE `_coa_karazhan_prince_weapons`;
