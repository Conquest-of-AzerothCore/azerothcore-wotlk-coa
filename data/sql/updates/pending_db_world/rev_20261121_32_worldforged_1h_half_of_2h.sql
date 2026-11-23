UPDATE `worldforged_upgrade` `w`
JOIN `item_template` `t` ON `t`.`entry` = `w`.`target_item`
JOIN (VALUES
ROW('1H', 60, 14650), ROW('1H', 64, 21700), ROW('1H', 67, 21700), ROW('1H', 70, 32100), ROW('1H', 73, 47500), ROW('1H', 77, 70300), ROW('1H', 81, 104050), ROW('1H', 88, 153950),
ROW('2H', 60, 29300), ROW('2H', 64, 43400), ROW('2H', 67, 43400), ROW('2H', 70, 64200), ROW('2H', 73, 95000), ROW('2H', 77, 140600), ROW('2H', 81, 208100), ROW('2H', 88, 307900)
) AS `p` (`price_group`, `item_level`, `cost`)
    ON `p`.`item_level` = `t`.`ItemLevel`
    AND `p`.`price_group` = CASE
        WHEN `t`.`InventoryType` IN (13, 14, 21, 22, 23) THEN '1H'
        WHEN `t`.`InventoryType` = 17 THEN '2H'
    END
SET `w`.`cost` = `p`.`cost`;
