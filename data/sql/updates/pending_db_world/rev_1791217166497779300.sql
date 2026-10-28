-- Random Classic Dungeon Heroic (1258) and Mythic (2258) completion rewards, from the Ascension client quest cache
-- (AscensionDB client captures, conquest-of-azeroth, 2026-09-12)
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `RewardMoney`, `Flags`, `RewardItem1`, `RewardAmount1`, `LogTitle`)
VALUES
(90189, 2, 60, 60, 8, 0, 136, 375250, 350, 'Classic Random Heroic 60 (1st) [Random Classic Dungeon Heroic]'),
(90191, 2, 64, 60, 8, 0, 136, 375250, 350, 'Classic Random Heroic 60 (Nth) [Random Classic Dungeon Heroic]'),
(90209, 2, 60, 60, 8, 65000, 136, 375250, 550, 'Classic Random Mythic 60 (1st) [Random Classic Dungeon Mythic]'),
(90211, 2, 64, 60, 8, 65000, 136, 375250, 550, 'Classic Random Mythic 60 (Nth) [Random Classic Dungeon Mythic]')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `LogTitle` = VALUES(`LogTitle`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (90189, 90191, 90209, 90211);
INSERT INTO `quest_template_addon` (`ID`, `SpecialFlags`) VALUES
(90189, 9),
(90191, 9),
(90209, 9),
(90211, 9);

DELETE FROM `lfg_dungeon_rewards` WHERE `dungeonId` IN (1258, 2258);
INSERT INTO `lfg_dungeon_rewards` (`dungeonId`, `maxLevel`, `firstQuestId`, `otherQuestId`) VALUES
(1258, 60, 90189, 90191),
(2258, 60, 90209, 90211);
