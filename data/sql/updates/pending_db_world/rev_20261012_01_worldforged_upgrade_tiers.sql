-- Worldforged items upgrade through six tiers; each tier above the first is unlocked account-wide by a raid boss kill
ALTER TABLE `worldforged_upgrade`
  ADD COLUMN `unlock_creature` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'raid boss whose kill on the account unlocks the recipe; 0 is always open';

DELETE FROM `worldforged_upgrade` WHERE `unlock_creature` = 14834;
INSERT INTO `worldforged_upgrade` (`id`, `store`, `base_item`, `target_item`, `cost`, `unlock_creature`)
SELECT `t1`.`target_item` + 2000, `t1`.`store`, `t1`.`target_item`, `t1`.`target_item` + 2000, `t1`.`cost` * 1.5, 14834
FROM `worldforged_upgrade` `t1`
JOIN `item_template` `cur` ON `cur`.`entry` = `t1`.`target_item`
JOIN `item_template` `nxt` ON `nxt`.`entry` = `t1`.`target_item` + 2000
WHERE `t1`.`unlock_creature` = 0 AND `nxt`.`name` = `cur`.`name` AND `nxt`.`description` LIKE '@Worldforged@%'
  AND `nxt`.`ItemLevel` > `cur`.`ItemLevel`
ORDER BY `t1`.`id`;

DELETE FROM `worldforged_upgrade` WHERE `unlock_creature` = 11502;
INSERT INTO `worldforged_upgrade` (`id`, `store`, `base_item`, `target_item`, `cost`, `unlock_creature`)
SELECT `t1`.`target_item` + 14000, `t1`.`store`, `prev`.`target_item`, `t1`.`target_item` + 14000, `t1`.`cost` * 2.0, 11502
FROM `worldforged_upgrade` `t1`
JOIN `worldforged_upgrade` `prev` ON `prev`.`target_item` = `t1`.`target_item` + 2000 AND `prev`.`unlock_creature` = 14834
JOIN `item_template` `cur` ON `cur`.`entry` = `prev`.`target_item`
JOIN `item_template` `nxt` ON `nxt`.`entry` = `t1`.`target_item` + 14000
WHERE `t1`.`unlock_creature` = 0 AND `nxt`.`name` = `cur`.`name` AND `nxt`.`description` LIKE '@Worldforged@%'
  AND `nxt`.`ItemLevel` > `cur`.`ItemLevel`
ORDER BY `t1`.`id`;

DELETE FROM `worldforged_upgrade` WHERE `unlock_creature` = 10184;
INSERT INTO `worldforged_upgrade` (`id`, `store`, `base_item`, `target_item`, `cost`, `unlock_creature`)
SELECT `t1`.`target_item` + 4000, `t1`.`store`, `prev`.`target_item`, `t1`.`target_item` + 4000, `t1`.`cost` * 2.5, 10184
FROM `worldforged_upgrade` `t1`
JOIN `worldforged_upgrade` `prev` ON `prev`.`target_item` = `t1`.`target_item` + 14000 AND `prev`.`unlock_creature` = 11502
JOIN `item_template` `cur` ON `cur`.`entry` = `prev`.`target_item`
JOIN `item_template` `nxt` ON `nxt`.`entry` = `t1`.`target_item` + 4000
WHERE `t1`.`unlock_creature` = 0 AND `nxt`.`name` = `cur`.`name` AND `nxt`.`description` LIKE '@Worldforged@%'
  AND `nxt`.`ItemLevel` > `cur`.`ItemLevel`
ORDER BY `t1`.`id`;

DELETE FROM `worldforged_upgrade` WHERE `unlock_creature` = 11583;
INSERT INTO `worldforged_upgrade` (`id`, `store`, `base_item`, `target_item`, `cost`, `unlock_creature`)
SELECT `t1`.`target_item` + 6000, `t1`.`store`, `prev`.`target_item`, `t1`.`target_item` + 6000, `t1`.`cost` * 3.0, 11583
FROM `worldforged_upgrade` `t1`
JOIN `worldforged_upgrade` `prev` ON `prev`.`target_item` = `t1`.`target_item` + 4000 AND `prev`.`unlock_creature` = 10184
JOIN `item_template` `cur` ON `cur`.`entry` = `prev`.`target_item`
JOIN `item_template` `nxt` ON `nxt`.`entry` = `t1`.`target_item` + 6000
WHERE `t1`.`unlock_creature` = 0 AND `nxt`.`name` = `cur`.`name` AND `nxt`.`description` LIKE '@Worldforged@%'
  AND `nxt`.`ItemLevel` > `cur`.`ItemLevel`
ORDER BY `t1`.`id`;

DELETE FROM `worldforged_upgrade` WHERE `unlock_creature` = 15727;
INSERT INTO `worldforged_upgrade` (`id`, `store`, `base_item`, `target_item`, `cost`, `unlock_creature`)
SELECT `t1`.`target_item` + 8000, `t1`.`store`, `prev`.`target_item`, `t1`.`target_item` + 8000, `t1`.`cost` * 3.5, 15727
FROM `worldforged_upgrade` `t1`
JOIN `worldforged_upgrade` `prev` ON `prev`.`target_item` = `t1`.`target_item` + 6000 AND `prev`.`unlock_creature` = 11583
JOIN `item_template` `cur` ON `cur`.`entry` = `prev`.`target_item`
JOIN `item_template` `nxt` ON `nxt`.`entry` = `t1`.`target_item` + 8000
WHERE `t1`.`unlock_creature` = 0 AND `nxt`.`name` = `cur`.`name` AND `nxt`.`description` LIKE '@Worldforged@%'
  AND `nxt`.`ItemLevel` > `cur`.`ItemLevel`
ORDER BY `t1`.`id`;
