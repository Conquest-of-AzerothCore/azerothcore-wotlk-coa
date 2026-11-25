START TRANSACTION;

-- Classic level-60 PvE Power by inventory type, independent of quality and item level.
CREATE TEMPORARY TABLE `_coa_tbc_slot_pve_power` (
    `entry` INT UNSIGNED PRIMARY KEY,
    `power` SMALLINT UNSIGNED NOT NULL
) ENGINE=InnoDB;

DELETE FROM `_coa_tbc_slot_pve_power`;
INSERT INTO `_coa_tbc_slot_pve_power` (`entry`, `power`)
SELECT `item`.`entry`, CASE
    WHEN `item`.`InventoryType` IN (2, 9, 11, 12, 16) THEN 20
    WHEN `item`.`InventoryType` IN (3, 6, 8, 10) THEN 25
    WHEN `item`.`InventoryType` IN (1, 5, 7, 20) THEN 38
    WHEN `item`.`InventoryType` IN (15, 25, 26, 28) THEN 45
    WHEN `item`.`InventoryType` IN (13, 14, 21, 22, 23) THEN 48
    WHEN `item`.`InventoryType` = 17 THEN 96
END
FROM `item_template` AS `item`
JOIN (
    SELECT `entry` FROM `coa_dungeon_rescale_item` WHERE `pve_power` > 0
    UNION
    SELECT `entry` FROM `coa_zone_item_budget` WHERE `zone_id` = 3483 AND `pve_power` > 0
    UNION
    SELECT `entry` FROM `coa_profession_item_budget` WHERE `expansion` = 1 AND `pve_power` > 0
) AS `converted` USING (`entry`)
WHERE `item`.`InventoryType` IN (1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 20, 21, 22, 23, 25, 26, 28)
    AND `item`.`spelltrigger_4` = 1 AND `item`.`spellid_4` BETWEEN 101601 AND 101699;

UPDATE `item_template` AS `item`
JOIN `_coa_tbc_slot_pve_power` AS `slot` ON `slot`.`entry` = `item`.`entry`
SET `item`.`spellid_4` = 101600 + `slot`.`power`;

UPDATE `coa_dungeon_rescale_item` AS `item`
JOIN `_coa_tbc_slot_pve_power` AS `slot` ON `slot`.`entry` = `item`.`entry`
SET `item`.`pve_power` = `slot`.`power`
WHERE `item`.`pve_power` > 0;

UPDATE `coa_zone_item_budget` AS `item`
JOIN `_coa_tbc_slot_pve_power` AS `slot` ON `slot`.`entry` = `item`.`entry`
SET `item`.`pve_power` = `slot`.`power`
WHERE `item`.`zone_id` = 3483 AND `item`.`pve_power` > 0;

UPDATE `coa_profession_item_budget` AS `item`
JOIN `_coa_tbc_slot_pve_power` AS `slot` ON `slot`.`entry` = `item`.`entry`
SET `item`.`pve_power` = `slot`.`power`
WHERE `item`.`expansion` = 1 AND `item`.`pve_power` > 0;

DROP TEMPORARY TABLE `_coa_tbc_slot_pve_power`;
COMMIT;
