UPDATE `worldforged_upgrade` `w`
JOIN `item_template` `t` ON `t`.`entry` = `w`.`target_item`
JOIN (VALUES
ROW('1H', 60, 20000), ROW('1H', 64, 29600), ROW('1H', 67, 29600), ROW('1H', 70, 43800), ROW('1H', 73, 64850), ROW('1H', 77, 95950), ROW('1H', 81, 142000), ROW('1H', 88, 210200),
ROW('Ranged', 60, 20000), ROW('Ranged', 64, 29600), ROW('Ranged', 67, 29600), ROW('Ranged', 70, 43800), ROW('Ranged', 73, 64850), ROW('Ranged', 77, 95950), ROW('Ranged', 81, 142000), ROW('Ranged', 88, 210200),
ROW('2H', 60, 26650), ROW('2H', 64, 39450), ROW('2H', 67, 39450), ROW('2H', 70, 58350), ROW('2H', 73, 86400), ROW('2H', 77, 127850), ROW('2H', 81, 189250), ROW('2H', 88, 280050),
ROW('Main', 60, 26650), ROW('Main', 64, 39450), ROW('Main', 67, 39450), ROW('Main', 70, 58350), ROW('Main', 73, 86400), ROW('Main', 77, 127850), ROW('Main', 81, 189250), ROW('Main', 88, 280050),
ROW('Off', 60, 20000), ROW('Off', 64, 29600), ROW('Off', 67, 29600), ROW('Off', 70, 43800), ROW('Off', 73, 64850), ROW('Off', 77, 95950), ROW('Off', 81, 142000), ROW('Off', 88, 210200),
ROW('Ring', 60, 24450), ROW('Ring', 64, 36200), ROW('Ring', 67, 36200), ROW('Ring', 70, 53550), ROW('Ring', 73, 79250), ROW('Ring', 77, 117300), ROW('Ring', 81, 173600), ROW('Ring', 88, 256950),
ROW('Neck', 60, 24450), ROW('Neck', 64, 36200), ROW('Neck', 67, 36200), ROW('Neck', 70, 53550), ROW('Neck', 73, 79250), ROW('Neck', 77, 117300), ROW('Neck', 81, 173600), ROW('Neck', 88, 256950),
ROW('Trinket', 60, 35000), ROW('Trinket', 64, 51800), ROW('Trinket', 67, 51800), ROW('Trinket', 70, 76650), ROW('Trinket', 73, 113450), ROW('Trinket', 77, 167900), ROW('Trinket', 81, 248550), ROW('Trinket', 88, 367800)
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
