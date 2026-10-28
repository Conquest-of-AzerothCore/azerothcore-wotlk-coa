-- Dungeon Spoils (2021814): the Classic Random reward quests give one, so the Dungeon Finder shows them as a reward.
-- Outside the Dungeon Finder the final boss of every normal vanilla dungeon gives one to each player
-- (CoADungeonFinalBossReward). They open into exactly one vanilla dungeon item (coa_dungeon_loot_variant), chosen
-- when they are first opened from the items that fit the opener's level (CoADungeonSpoilsLevel).
UPDATE `quest_template` SET `RewardItem2` = 2021814, `RewardAmount2` = 1
WHERE `ID` IN (24881, 24882, 24889, 24890, 24891, 24892, 24893, 24894);
UPDATE `quest_template` SET `RewardItem3` = 2021814, `RewardAmount3` = 1 WHERE `ID` IN (24883, 24884, 24885, 24886);

DELETE FROM `reference_loot_template` WHERE `Entry` = 2021814;
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT DISTINCT 2021814, `v`.`base_item`, 0, 0, 0, 1, 1, 1, 1, 'Dungeon Spoils - dungeon item'
FROM `coa_dungeon_loot_variant` `v` JOIN `item_template` `i` ON `i`.`entry` = `v`.`base_item`;

DELETE FROM `item_loot_template` WHERE `Entry` = 2021814;
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(2021814, 1, 2021814, 100, 0, 1, 0, 1, 1, 'Dungeon Spoils - one dungeon item');

UPDATE `item_template` SET `Quality` = 4, `Flags` = `Flags` | 4, `RequiredLevel` = 0, `ScriptName` = 'item_coa_dungeon_spoils'
WHERE `entry` = 2021814;
