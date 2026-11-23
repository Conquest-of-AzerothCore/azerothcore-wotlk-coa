UPDATE `worldforged_upgrade` `w`
JOIN `item_template` `t` ON `t`.`entry` = `w`.`target_item`
JOIN (VALUES
ROW('1H', 60, 5850), ROW('2H', 60, 11700), ROW('Main', 60, 10650), ROW('Ranged', 60, 8000),
ROW('Off', 60, 8000), ROW('Ring', 60, 9800), ROW('Neck', 60, 9800), ROW('Trinket', 60, 14000)
) AS `p` (`price_group`, `item_level`, `cost`)
    ON `p`.`item_level` = `t`.`ItemLevel`
    AND `p`.`price_group` = CASE
        WHEN `t`.`InventoryType` IN (13, 14, 21, 22, 23) THEN '1H'
        WHEN `t`.`InventoryType` IN (15, 25, 26, 28) THEN 'Ranged'
        WHEN `t`.`InventoryType` = 17 THEN '2H'
        WHEN `t`.`InventoryType` IN (1, 3, 5, 7, 20) THEN 'Main'
        WHEN `t`.`InventoryType` IN (6, 8, 9, 10, 16) THEN 'Off'
        WHEN `t`.`InventoryType` = 11 THEN 'Ring'
        WHEN `t`.`InventoryType` = 2 THEN 'Neck'
        WHEN `t`.`InventoryType` = 12 THEN 'Trinket'
    END
SET `w`.`cost` = `p`.`cost`;
