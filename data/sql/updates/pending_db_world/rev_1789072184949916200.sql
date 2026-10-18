-- Exiles visible lists are capped at 20 rows; absence never means a drop should be removed.
-- Stated probabilities; observed counts are zero. No empirical drop-rate claim.
-- New rows: Reference=0, QuestRequired=0, LootMode=1, GroupId=0, MinCount=MaxCount=1.
-- Existing stacks and unrelated rows are preserved. Shared/reference/conditional loot is excluded.
CREATE TEMPORARY TABLE `_coa_loot_patch` (
  `Entry` INT UNSIGNED NOT NULL, `Name` VARBINARY(400) NOT NULL, `OldLootId` INT UNSIGNED NOT NULL,
  `Item` INT UNSIGNED NOT NULL, `Chance` FLOAT NOT NULL,
  PRIMARY KEY (`Entry`, `Item`)
) ENGINE=InnoDB;
DELETE FROM `_coa_loot_patch`;
INSERT INTO `_coa_loot_patch` VALUES
(10161, CONVERT(0x526f6f6b657279205768656c70 USING utf8mb4), 0, 1180298, 1.0),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 14284, 0.01),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 14287, 0.01),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 14288, 0.01),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 14293, 0.01),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 14295, 0.01),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 14297, 0.01),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 14298, 0.01),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 14299, 0.01),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 14302, 0.01),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 14304, 0.01),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 14305, 0.01),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 14309, 0.01),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 16250, 2.0),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 59882, 1.0),
(10220, CONVERT(0x48616c79636f6e USING utf8mb4), 10220, 97730, 6.0),
(10264, CONVERT(0x536f6c616b617220466c616d65777265617468 USING utf8mb4), 10264, 59888, 1.0),
(10264, CONVERT(0x536f6c616b617220466c616d65777265617468 USING utf8mb4), 10264, 97730, 6.0),
(10264, CONVERT(0x536f6c616b617220466c616d65777265617468 USING utf8mb4), 10264, 1180305, 1.0),
(10268, CONVERT(0x47697a72756c2074686520536c6176656e6572 USING utf8mb4), 10268, 59889, 1.0),
(10268, CONVERT(0x47697a72756c2074686520536c6176656e6572 USING utf8mb4), 10268, 97730, 6.0),
(10584, CONVERT(0x55726f6b20446f6f6d686f776c USING utf8mb4), 10584, 59920, 1.0),
(10584, CONVERT(0x55726f6b20446f6f6d686f776c USING utf8mb4), 10584, 97730, 6.0),
(10596, CONVERT(0x4d6f7468657220536d6f6c646572776562 USING utf8mb4), 10596, 14284, 0.01),
(10596, CONVERT(0x4d6f7468657220536d6f6c646572776562 USING utf8mb4), 10596, 14287, 0.01),
(10596, CONVERT(0x4d6f7468657220536d6f6c646572776562 USING utf8mb4), 10596, 14288, 0.01),
(10596, CONVERT(0x4d6f7468657220536d6f6c646572776562 USING utf8mb4), 10596, 14293, 0.01),
(10596, CONVERT(0x4d6f7468657220536d6f6c646572776562 USING utf8mb4), 10596, 14295, 0.01),
(10596, CONVERT(0x4d6f7468657220536d6f6c646572776562 USING utf8mb4), 10596, 14297, 0.01),
(10596, CONVERT(0x4d6f7468657220536d6f6c646572776562 USING utf8mb4), 10596, 14298, 0.01),
(10596, CONVERT(0x4d6f7468657220536d6f6c646572776562 USING utf8mb4), 10596, 14299, 0.01),
(10596, CONVERT(0x4d6f7468657220536d6f6c646572776562 USING utf8mb4), 10596, 14302, 0.01),
(10596, CONVERT(0x4d6f7468657220536d6f6c646572776562 USING utf8mb4), 10596, 16250, 2.0),
(10596, CONVERT(0x4d6f7468657220536d6f6c646572776562 USING utf8mb4), 10596, 59921, 1.0),
(10596, CONVERT(0x4d6f7468657220536d6f6c646572776562 USING utf8mb4), 10596, 97730, 6.0);
CREATE TEMPORARY TABLE `_coa_loot_scope` (`Entry` INT UNSIGNED PRIMARY KEY) ENGINE=InnoDB;
DELETE FROM `_coa_loot_scope`;
INSERT INTO `_coa_loot_scope`
SELECT DISTINCT `c`.`entry` FROM `creature_template` AS `c`
JOIN `_coa_loot_patch` AS `p` ON `p`.`Entry` = `c`.`entry`
WHERE `c`.`name` = `p`.`Name` AND `c`.`lootid` IN (0, `c`.`entry`)
AND (`c`.`lootid` = `p`.`OldLootId` OR `c`.`lootid` = `c`.`entry`)
AND NOT EXISTS (SELECT 1 FROM `creature_template` AS `o`
  WHERE `o`.`lootid` = `c`.`entry` AND `o`.`entry` <> `c`.`entry`)
AND NOT EXISTS (SELECT 1 FROM `conditions` AS `k`
  WHERE `k`.`SourceTypeOrReferenceId` = 1 AND `k`.`SourceGroup` = `c`.`entry`)
AND NOT EXISTS (SELECT 1 FROM `creature_loot_template` AS `r`
  WHERE `r`.`Entry` = `c`.`entry` AND (`r`.`Reference` <> 0 OR `c`.`lootid` = 0));
CREATE TEMPORARY TABLE `_coa_quest_items` (`Item` INT UNSIGNED PRIMARY KEY) ENGINE=InnoDB;
DELETE FROM `_coa_quest_items`;
INSERT INTO `_coa_quest_items`
SELECT `entry` FROM `item_template` WHERE `class` = 12 OR `startquest` <> 0 OR `Bonding` = 4
UNION SELECT `RequiredItemId1` FROM `quest_template` WHERE `RequiredItemId1` <> 0
UNION SELECT `RequiredItemId2` FROM `quest_template` WHERE `RequiredItemId2` <> 0
UNION SELECT `RequiredItemId3` FROM `quest_template` WHERE `RequiredItemId3` <> 0
UNION SELECT `RequiredItemId4` FROM `quest_template` WHERE `RequiredItemId4` <> 0
UNION SELECT `RequiredItemId5` FROM `quest_template` WHERE `RequiredItemId5` <> 0
UNION SELECT `RequiredItemId6` FROM `quest_template` WHERE `RequiredItemId6` <> 0
UNION SELECT `ItemDrop1` FROM `quest_template` WHERE `ItemDrop1` <> 0
UNION SELECT `ItemDrop2` FROM `quest_template` WHERE `ItemDrop2` <> 0
UNION SELECT `ItemDrop3` FROM `quest_template` WHERE `ItemDrop3` <> 0
UNION SELECT `ItemDrop4` FROM `quest_template` WHERE `ItemDrop4` <> 0;
START TRANSACTION;
DELETE `p` FROM `_coa_loot_patch` AS `p`
LEFT JOIN `_coa_loot_scope` AS `s` ON `s`.`Entry` = `p`.`Entry`
LEFT JOIN `item_template` AS `i` ON `i`.`entry` = `p`.`Item`
LEFT JOIN `_coa_quest_items` AS `q` ON `q`.`Item` = `p`.`Item`
WHERE `s`.`Entry` IS NULL OR `i`.`entry` IS NULL OR `q`.`Item` IS NOT NULL;
UPDATE `creature_template` AS `c` JOIN `_coa_loot_patch` AS `p` ON `p`.`Entry` = `c`.`entry`
SET `c`.`lootid` = `c`.`entry` WHERE `c`.`lootid` = 0;
-- Only unchanged rows previously added by this migration can be replaced.
CREATE TEMPORARY TABLE `_coa_owned` (
  `Entry` INT UNSIGNED NOT NULL, `Item` INT UNSIGNED NOT NULL,
  `Reference` INT NOT NULL, `GroupId` TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (`Entry`, `Item`, `Reference`, `GroupId`)
) ENGINE=InnoDB;
DELETE FROM `_coa_owned`;
INSERT INTO `_coa_owned`
SELECT `l`.`Entry`, `l`.`Item`, `l`.`Reference`, `l`.`GroupId` FROM `creature_loot_template` AS `l`
JOIN `_coa_loot_patch` AS `p` ON `p`.`Entry` = `l`.`Entry` AND `p`.`Item` = `l`.`Item`
WHERE `l`.`Reference` = 0 AND `l`.`GroupId` = 0 AND `l`.`QuestRequired` = 0 AND `l`.`LootMode` = 1
AND `l`.`MinCount` = 1 AND `l`.`MaxCount` = 1 AND `l`.`Chance` = `p`.`Chance`
AND BINARY `l`.`Comment` = BINARY 'Exiles stated chance; default stack 1';
-- _coa_owned contains exactly the four primary-key columns; NATURAL JOIN matches all four.
DELETE `l` FROM `creature_loot_template` AS `l` NATURAL JOIN `_coa_owned`;
INSERT INTO `creature_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT `p`.`Entry`, `p`.`Item`, 0, `p`.`Chance`, 0, 1, 0, 1, 1, 'Exiles stated chance; default stack 1'
FROM `_coa_loot_patch` AS `p`
WHERE NOT EXISTS (SELECT 1 FROM `creature_loot_template` AS `l`
  WHERE `l`.`Entry` = `p`.`Entry` AND `l`.`Item` = `p`.`Item`);
COMMIT;
DROP TEMPORARY TABLE `_coa_owned`, `_coa_quest_items`, `_coa_loot_scope`, `_coa_loot_patch`;
