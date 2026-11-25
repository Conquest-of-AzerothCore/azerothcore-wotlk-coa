-- Complete the missing T1 vendor sets, retaining existing offers and their prices.
-- Infer slot-token costs from each vendor's Regalia of Prophecy offers.
DROP TEMPORARY TABLE IF EXISTS `_coa_t1_vendor_missing`;
CREATE TEMPORARY TABLE `_coa_t1_vendor_missing` AS
SELECT `tiers`.`vendor` AS `entry`, `it`.`entry` AS `item`, `costs`.`token_cost` AS `ExtendedCost`
FROM `item_template` `it`
JOIN (
    SELECT 91000001 AS `vendor`, 65 AS `ilvl`
    UNION ALL SELECT 91000002, 68
    UNION ALL SELECT 91000003, 72
    UNION ALL SELECT 91000004, 75
) `tiers` ON `it`.`ItemLevel` = `tiers`.`ilvl`
JOIN (
    SELECT `nv`.`entry` AS `vendor`,
        CASE WHEN `ref`.`InventoryType` IN (5, 20) THEN 5 ELSE `ref`.`InventoryType` END AS `slot_type`,
        MIN(`nv`.`ExtendedCost`) AS `token_cost`
    FROM `npc_vendor` `nv` JOIN `item_template` `ref` ON `ref`.`entry` = `nv`.`item`
    WHERE `nv`.`entry` BETWEEN 91000001 AND 91000004 AND `ref`.`ItemSet` = 202
        AND `ref`.`name` NOT LIKE 'Bloodforged%'
    GROUP BY `nv`.`entry`, CASE WHEN `ref`.`InventoryType` IN (5, 20) THEN 5 ELSE `ref`.`InventoryType` END
) `costs` ON `costs`.`vendor` = `tiers`.`vendor` AND `costs`.`slot_type` =
    CASE WHEN `it`.`InventoryType` IN (5, 20) THEN 5 ELSE `it`.`InventoryType` END
WHERE `it`.`ItemSet` IN (406, 1205, 1208, 1209, 1210, 1219, 1223, 1226, 1227, 1321, 2020)
    AND `it`.`name` NOT LIKE 'Bloodforged%'
    AND NOT EXISTS (
        SELECT 1 FROM `npc_vendor` `existing`
        WHERE `existing`.`entry` = `tiers`.`vendor` AND `existing`.`item` = `it`.`entry`
    );

DELETE FROM `npc_vendor` WHERE (`entry`, `item`) IN (SELECT `entry`, `item` FROM `_coa_t1_vendor_missing`);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`)
SELECT `entry`, 0, `item`, 0, 0, `ExtendedCost` FROM `_coa_t1_vendor_missing`;
DROP TEMPORARY TABLE `_coa_t1_vendor_missing`;
