-- Give custom weapons and armour (entry 60000 and above) the disenchant bracket of the closest stock item at or
-- below their item level. Items a vendor sells for gold stay non-disenchantable so they cannot be bought and
-- disenchanted for materials without limit. Vanity collection items (the entries of VanityCollection.dbc that
-- pass the filter below) stay non-disenchantable too.
-- Donors are disenchantable stock entries below 60000 with the same class, slot and quality, preferring the
-- same sub class at an equal donor level; the most common bracket wins, then the lowest DisenchantID and skill.
-- The authored RequiredDisenchantSkill is kept; level-lifted copies re-bracket at runtime with the same rule.
DROP TEMPORARY TABLE IF EXISTS `_coa_disenchant_donors_v1`;
CREATE TEMPORARY TABLE `_coa_disenchant_donors_v1` (
    `class` INT UNSIGNED NOT NULL,
    `subclass` INT NOT NULL,
    `slot` INT UNSIGNED NOT NULL,
    `Quality` INT UNSIGNED NOT NULL,
    `ItemLevel` INT UNSIGNED NOT NULL,
    `DisenchantID` INT UNSIGNED NOT NULL,
    `RequiredDisenchantSkill` INT NOT NULL,
    `donors` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`class`, `subclass`, `slot`, `Quality`, `ItemLevel`, `DisenchantID`, `RequiredDisenchantSkill`)
) ENGINE=InnoDB;
DELETE FROM `_coa_disenchant_donors_v1`;
INSERT INTO `_coa_disenchant_donors_v1`
    (`class`, `subclass`, `slot`, `Quality`, `ItemLevel`, `DisenchantID`, `RequiredDisenchantSkill`, `donors`)
SELECT `donor`.`class`, `donor`.`subclass`, `donor`.`slot`, `donor`.`Quality`, `donor`.`ItemLevel`,
    `donor`.`DisenchantID`, `donor`.`RequiredDisenchantSkill`, COUNT(*)
FROM (
    SELECT `class`, `subclass`, IF(`InventoryType` = 20, 5, `InventoryType`) AS `slot`, `Quality`, `ItemLevel`,
        `DisenchantID`, `RequiredDisenchantSkill`
    FROM `item_template`
    WHERE `entry` < 60000 AND `DisenchantID` <> 0 AND `RequiredDisenchantSkill` >= 0
        AND `class` IN (2, 4) AND `Quality` <= 5 AND `InventoryType` NOT IN (0, 4, 19) AND `ItemLevel` > 0
        AND `ScalingStatDistribution` = 0 AND `startquest` = 0
    UNION ALL
    SELECT `class`, -1, IF(`InventoryType` = 20, 5, `InventoryType`), `Quality`, `ItemLevel`,
        `DisenchantID`, `RequiredDisenchantSkill`
    FROM `item_template`
    WHERE `entry` < 60000 AND `DisenchantID` <> 0 AND `RequiredDisenchantSkill` >= 0
        AND `class` IN (2, 4) AND `Quality` <= 5 AND `InventoryType` NOT IN (0, 4, 19) AND `ItemLevel` > 0
        AND `ScalingStatDistribution` = 0 AND `startquest` = 0
) AS `donor`
GROUP BY `donor`.`class`, `donor`.`subclass`, `donor`.`slot`, `donor`.`Quality`, `donor`.`ItemLevel`,
    `donor`.`DisenchantID`, `donor`.`RequiredDisenchantSkill`;

DROP TEMPORARY TABLE IF EXISTS `_coa_disenchant_brackets_v1`;
CREATE TEMPORARY TABLE `_coa_disenchant_brackets_v1` (
    `class` INT UNSIGNED NOT NULL,
    `subclass` INT NOT NULL,
    `slot` INT UNSIGNED NOT NULL,
    `Quality` INT UNSIGNED NOT NULL,
    `ItemLevel` INT UNSIGNED NOT NULL,
    `DisenchantID` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`class`, `subclass`, `slot`, `Quality`, `ItemLevel`)
) ENGINE=InnoDB;
DELETE FROM `_coa_disenchant_brackets_v1`;
INSERT INTO `_coa_disenchant_brackets_v1` (`class`, `subclass`, `slot`, `Quality`, `ItemLevel`, `DisenchantID`)
SELECT `class`, `subclass`, `slot`, `Quality`, `ItemLevel`, `DisenchantID`
FROM (
    SELECT `class`, `subclass`, `slot`, `Quality`, `ItemLevel`, `DisenchantID`,
        ROW_NUMBER() OVER (PARTITION BY `class`, `subclass`, `slot`, `Quality`, `ItemLevel`
            ORDER BY `donors` DESC, `DisenchantID`, `RequiredDisenchantSkill`) AS `choice`
    FROM `_coa_disenchant_donors_v1`
) AS `ranked`
WHERE `choice` = 1;

DROP TEMPORARY TABLE IF EXISTS `_coa_disenchant_targets_v1`;
CREATE TEMPORARY TABLE `_coa_disenchant_targets_v1` (
    `entry` INT UNSIGNED NOT NULL PRIMARY KEY,
    `class` INT UNSIGNED NOT NULL,
    `subclass` INT NOT NULL,
    `slot` INT UNSIGNED NOT NULL,
    `Quality` INT UNSIGNED NOT NULL,
    `ItemLevel` INT UNSIGNED NOT NULL,
    `subclassLevel` INT UNSIGNED DEFAULT NULL,
    `slotLevel` INT UNSIGNED DEFAULT NULL
) ENGINE=InnoDB;
DELETE FROM `_coa_disenchant_targets_v1`;
INSERT INTO `_coa_disenchant_targets_v1` (`entry`, `class`, `subclass`, `slot`, `Quality`, `ItemLevel`)
SELECT `entry`, `class`, `subclass`, IF(`InventoryType` = 20, 5, `InventoryType`), `Quality`, `ItemLevel`
FROM `item_template`
WHERE `entry` >= 60000 AND `DisenchantID` = 0 AND `RequiredDisenchantSkill` >= 0
    AND `class` IN (2, 4) AND `Quality` BETWEEN 2 AND 4 AND `InventoryType` NOT IN (0, 4, 19) AND `ItemLevel` > 0
    AND `ScalingStatDistribution` = 0 AND `startquest` = 0;

DELETE `target`
FROM `_coa_disenchant_targets_v1` AS `target`
INNER JOIN (
    SELECT `item` FROM `npc_vendor` WHERE `ExtendedCost` = 0
    UNION
    SELECT `item` FROM `game_event_npc_vendor` WHERE `ExtendedCost` = 0
) AS `goldVendor` ON `goldVendor`.`item` = `target`.`entry`;

DELETE FROM `_coa_disenchant_targets_v1`
WHERE `entry` IN (80011, 100498, 558544, 558549, 558550, 558551, 558552, 558553, 558554, 558555, 558556, 558557,
    558558, 558559, 558564, 558791, 558792, 558793, 558795, 558796, 559536);

UPDATE `_coa_disenchant_targets_v1` AS `target`
SET `target`.`subclassLevel` = (
    SELECT `bracket`.`ItemLevel`
    FROM `_coa_disenchant_brackets_v1` AS `bracket`
    WHERE `bracket`.`class` = `target`.`class` AND `bracket`.`subclass` = `target`.`subclass`
        AND `bracket`.`slot` = `target`.`slot` AND `bracket`.`Quality` = `target`.`Quality`
        AND `bracket`.`ItemLevel` <= `target`.`ItemLevel`
    ORDER BY `bracket`.`ItemLevel` DESC
    LIMIT 1);

UPDATE `_coa_disenchant_targets_v1` AS `target`
SET `target`.`slotLevel` = (
    SELECT `bracket`.`ItemLevel`
    FROM `_coa_disenchant_brackets_v1` AS `bracket`
    WHERE `bracket`.`class` = `target`.`class` AND `bracket`.`subclass` = -1
        AND `bracket`.`slot` = `target`.`slot` AND `bracket`.`Quality` = `target`.`Quality`
        AND `bracket`.`ItemLevel` <= `target`.`ItemLevel`
    ORDER BY `bracket`.`ItemLevel` DESC
    LIMIT 1);

UPDATE `_coa_disenchant_targets_v1`
SET `subclassLevel` = IF(`subclassLevel` IS NULL, 0, `subclassLevel`),
    `slotLevel` = IF(`slotLevel` IS NULL, 0, `slotLevel`);

UPDATE `item_template` AS `item`
INNER JOIN `_coa_disenchant_targets_v1` AS `target` ON `target`.`entry` = `item`.`entry`
INNER JOIN `_coa_disenchant_brackets_v1` AS `bracket` ON `bracket`.`class` = `target`.`class`
    AND `bracket`.`subclass` = IF(`target`.`slotLevel` > `target`.`subclassLevel`, -1, `target`.`subclass`)
    AND `bracket`.`slot` = `target`.`slot` AND `bracket`.`Quality` = `target`.`Quality`
    AND `bracket`.`ItemLevel` = GREATEST(`target`.`slotLevel`, `target`.`subclassLevel`)
SET `item`.`DisenchantID` = `bracket`.`DisenchantID`
WHERE `item`.`DisenchantID` = 0;

DROP TEMPORARY TABLE IF EXISTS `_coa_disenchant_targets_v1`;
DROP TEMPORARY TABLE IF EXISTS `_coa_disenchant_brackets_v1`;
DROP TEMPORARY TABLE IF EXISTS `_coa_disenchant_donors_v1`;
