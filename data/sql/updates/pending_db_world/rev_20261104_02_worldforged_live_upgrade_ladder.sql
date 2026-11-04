-- Live LootCollector WorldforgedUpgrades ladder: the first epic rank (item level 64 or 67) is the Zul'Gurub upgrade
-- and item level 70 the Molten Core (Tier 1) upgrade.
UPDATE `worldforged_upgrade` `u`
JOIN `item_template` `t` ON `t`.`entry` = `u`.`target_item`
SET `u`.`unlock_creature` = 14834
WHERE `u`.`unlock_creature` = 0 AND `t`.`Quality` = 4;

UPDATE `worldforged_upgrade` `u`
JOIN `item_template` `t` ON `t`.`entry` = `u`.`target_item`
SET `u`.`unlock_creature` = 11502
WHERE `u`.`unlock_creature` = 14834 AND `t`.`ItemLevel` >= 70;
