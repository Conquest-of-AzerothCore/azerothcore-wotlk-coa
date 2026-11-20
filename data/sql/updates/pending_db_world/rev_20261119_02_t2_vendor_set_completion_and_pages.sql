-- Complete the existing T2 set families using each difficulty's Netherwind slot prices.
START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS `_coa_t2_vendor_missing`;
CREATE TEMPORARY TABLE `_coa_t2_vendor_missing` AS
SELECT `costs`.`vendor` AS `entry`, `it`.`entry` AS `item`, `costs`.`token_cost` AS `ExtendedCost`
FROM `item_template` `it`
JOIN (
    SELECT `nv`.`entry` AS `vendor`, `ref`.`ItemLevel`,
        CASE WHEN `ref`.`InventoryType` IN (5, 20) THEN 5 ELSE `ref`.`InventoryType` END AS `slot_type`,
        MIN(`nv`.`ExtendedCost`) AS `token_cost`
    FROM `npc_vendor` `nv` JOIN `item_template` `ref` ON `ref`.`entry` = `nv`.`item`
    WHERE `nv`.`entry` BETWEEN 91000005 AND 91000008 AND `ref`.`ItemSet` = 210
        AND `ref`.`name` NOT LIKE 'Bloodforged%'
    GROUP BY `nv`.`entry`, `ref`.`ItemLevel`,
        CASE WHEN `ref`.`InventoryType` IN (5, 20) THEN 5 ELSE `ref`.`InventoryType` END
) `costs` ON `it`.`ItemLevel` = `costs`.`ItemLevel` AND `costs`.`slot_type` =
    CASE WHEN `it`.`InventoryType` IN (5, 20) THEN 5 ELSE `it`.`InventoryType` END
WHERE `it`.`ItemSet` IN (210, 212, 213, 214, 215, 216, 217, 218, 220, 404,
    1211, 1214, 1216, 1217, 1218, 1224, 1228, 2021, 2214)
    AND `it`.`name` NOT LIKE 'Bloodforged%'
    AND NOT EXISTS (SELECT 1 FROM `npc_vendor` `existing`
        WHERE `existing`.`entry` = `costs`.`vendor` AND `existing`.`item` = `it`.`entry`);

DELETE FROM `npc_vendor` WHERE (`entry`, `item`) IN (SELECT `entry`, `item` FROM `_coa_t2_vendor_missing`);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`)
SELECT `entry`, 0, `item`, 0, 0, `ExtendedCost` FROM `_coa_t2_vendor_missing`;
DROP TEMPORARY TABLE IF EXISTS `_coa_t2_vendor_missing`;

INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `type`)
VALUES
(91000109, 'T2 Normal - Part 1', 60, 60, 35, 128, 1, 7),
(91000110, 'T2 Normal - Part 2', 60, 60, 35, 128, 1, 7),
(91000111, 'T2 Heroic - Part 1', 60, 60, 35, 128, 1, 7),
(91000112, 'T2 Heroic - Part 2', 60, 60, 35, 128, 1, 7),
(91000113, 'T2 Mythic - Part 1', 60, 60, 35, 128, 1, 7),
(91000114, 'T2 Mythic - Part 2', 60, 60, 35, 128, 1, 7),
(91000115, 'T2 Ascended - Part 1', 60, 60, 35, 128, 1, 7),
(91000116, 'T2 Ascended - Part 2', 60, 60, 35, 128, 1, 7)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `npcflag` = VALUES(`npcflag`);

DELETE FROM `npc_vendor` WHERE `entry` BETWEEN 91000109 AND 91000116;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`)
SELECT 91000109 + (`v`.`entry` - 91000005) * 2 + CASE WHEN `i`.`ItemSet` <= 404 THEN 0 ELSE 1 END,
    `v`.`slot`, `v`.`item`, `v`.`maxcount`, `v`.`incrtime`, `v`.`ExtendedCost`, `v`.`VerifiedBuild`
FROM `npc_vendor` `v` JOIN `item_template` `i` ON `i`.`entry` = `v`.`item`
WHERE `v`.`entry` BETWEEN 91000005 AND 91000008;

COMMIT;
