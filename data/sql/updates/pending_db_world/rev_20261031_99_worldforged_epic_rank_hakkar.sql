-- Worldforged items climbed to an item level 67 epic rank without a raid kill, above Zul'Gurub's item level 63 loot.
-- Upgrades up to item level 64 stay open; the item level 67 epic ranks now open after Hakkar.
UPDATE `worldforged_upgrade` `u`
JOIN `item_template` `t` ON `t`.`entry` = `u`.`target_item`
SET `u`.`unlock_creature` = 14834
WHERE `u`.`unlock_creature` = 0 AND `t`.`Quality` = 4 AND `t`.`ItemLevel` > 64;
