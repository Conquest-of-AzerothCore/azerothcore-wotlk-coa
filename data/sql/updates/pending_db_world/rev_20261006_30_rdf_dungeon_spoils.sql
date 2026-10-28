-- Random Classic Dungeon Heroic (1258) and Mythic (2258) rewards: as on Ascension, finishing one through the Dungeon
-- Finder gives Dungeon Spoils (Heroic/Mythic), and the Dungeon Finder shows them as a reward.
UPDATE `quest_template` SET `RewardItem2` = 1202039, `RewardAmount2` = 1 WHERE `ID` = 90189;
UPDATE `quest_template` SET `RewardItem2` = 1202039, `RewardAmount2` = 1 WHERE `ID` = 90191;
UPDATE `quest_template` SET `RewardItem2` = 1027965, `RewardAmount2` = 1 WHERE `ID` = 90209;
UPDATE `quest_template` SET `RewardItem2` = 1027965, `RewardAmount2` = 1 WHERE `ID` = 90211;

-- Dungeon Spoils open into one or two random items, the Heroic or Mythic versions of the vanilla dungeon items
-- (coa_dungeon_loot_variant): one for sure and a second at 50 %.
DELETE FROM `reference_loot_template` WHERE `Entry` = 1202039;
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT DISTINCT 1202039, `v`.`heroic_item`, 0, 0, 0, 1, 1, 1, 1, 'Dungeon Spoils (Heroic) - Heroic dungeon item'
FROM `coa_dungeon_loot_variant` `v` JOIN `item_template` `i` ON `i`.`entry` = `v`.`heroic_item`;
DELETE FROM `reference_loot_template` WHERE `Entry` = 1027965;
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT DISTINCT 1027965, `v`.`mythic_item`, 0, 0, 0, 1, 1, 1, 1, 'Dungeon Spoils (Mythic) - Mythic dungeon item'
FROM `coa_dungeon_loot_variant` `v` JOIN `item_template` `i` ON `i`.`entry` = `v`.`mythic_item`;

DELETE FROM `item_loot_template` WHERE `Entry` IN (1202039, 1027965);
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(1202039, 1, 1202039, 100, 0, 1, 0, 1, 1, 'Dungeon Spoils (Heroic) - first Heroic dungeon item'),
(1202039, 2, 1202039, 50, 0, 1, 0, 1, 1, 'Dungeon Spoils (Heroic) - second Heroic dungeon item'),
(1027965, 1, 1027965, 100, 0, 1, 0, 1, 1, 'Dungeon Spoils (Mythic) - first Mythic dungeon item'),
(1027965, 2, 1027965, 50, 0, 1, 0, 1, 1, 'Dungeon Spoils (Mythic) - second Mythic dungeon item');

UPDATE `item_template` SET `Flags` = `Flags` | 4, `ScriptName` = 'item_coa_dungeon_spoils' WHERE `entry` IN (1202039, 1027965);
