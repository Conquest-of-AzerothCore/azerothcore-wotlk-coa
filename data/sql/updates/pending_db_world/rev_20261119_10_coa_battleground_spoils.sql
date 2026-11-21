-- Classic Battleground reward quests and Battleground Spoils bags (live CoA, AscensionDB conquest-of-azeroth captures)
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardArenaPoints`, `LogTitle`, `VerifiedBuild`) VALUES
(90001, 2, 25, 10, 4, 136, 1175636, 1, 375250, 500, 0, 'Classic Battleground 10-20 (Win)', 12340),
(90002, 2, 35, 21, 4, 136, 1175637, 1, 375250, 750, 0, 'Classic Battleground 21-30 (Win)', 12340),
(90003, 2, 44, 31, 4, 136, 1175638, 1, 375250, 750, 0, 'Classic Battleground 31-40 (Win)', 12340),
(90004, 2, 55, 41, 4, 136, 1175639, 1, 375250, 1000, 0, 'Classic Battleground 41-50 (Win)', 12340),
(90005, 2, 65, 51, 4, 136, 1175640, 1, 375250, 1000, 0, 'Classic Battleground 51-59 (Win)', 12340),
(90008, 2, 25, 10, 3, 136, 1675636, 1, 375250, 200, 0, 'Classic Battleground 10-20 (Loss)', 12340),
(90009, 2, 35, 21, 3, 136, 1675637, 1, 375250, 300, 0, 'Classic Battleground 21-30 (Loss)', 12340),
(90010, 2, 44, 31, 3, 136, 1675638, 1, 375250, 300, 0, 'Classic Battleground 31-40 (Loss)', 12340),
(90011, 2, 55, 41, 3, 136, 1675639, 1, 375250, 400, 0, 'Classic Battleground 41-50 (Loss)', 12340),
(90012, 2, 65, 51, 3, 136, 1675640, 1, 375250, 400, 0, 'Classic Battleground 51-59 (Loss)', 12340),
(190005, 2, 65, 60, 4, 136, 1175640, 1, 375250, 1000, 200, 'Classic Battleground 60 (Win)', 12340),
(190012, 2, 65, 60, 3, 136, 1675640, 1, 375250, 400, 100, 'Classic Battleground 60 (Loss)', 12340) ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `LogTitle` = VALUES(`LogTitle`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (90001, 90002, 90003, 90004, 90005, 90008, 90009, 90010, 90011, 90012, 190005, 190012);
INSERT INTO `quest_template_addon` (`ID`, `SpecialFlags`) VALUES
(90001, 9),
(90002, 9),
(90003, 9),
(90004, 9),
(90005, 9),
(90008, 9),
(90009, 9),
(90010, 9),
(90011, 9),
(90012, 9),
(190005, 9),
(190012, 9);

UPDATE `item_template` SET `ScriptName` = 'item_coa_dungeon_spoils', `Flags` = 134217740 WHERE `entry` IN (1175636, 1175637, 1175638, 1175639, 1175640, 1675636, 1675637, 1675638, 1675639, 1675640);

DELETE FROM `item_loot_template` WHERE `Entry` IN (1175636, 1175637, 1175638, 1175639, 1175640, 1675636, 1675637, 1675638, 1675639, 1675640);
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(1175636, 1, 2021814, 100, 0, 1, 0, 1, 1, 'Battleground Spoils 10-20 (Win) - one dungeon item'),
(1175637, 1, 2021814, 100, 0, 1, 0, 1, 1, 'Battleground Spoils 21-30 (Win) - one dungeon item'),
(1175638, 1, 2021814, 100, 0, 1, 0, 1, 1, 'Battleground Spoils 31-40 (Win) - one dungeon item'),
(1175639, 1, 2021814, 100, 0, 1, 0, 1, 1, 'Battleground Spoils 41-50 (Win) - one dungeon item'),
(1175640, 1, 2021814, 100, 0, 1, 0, 1, 1, 'Battleground Spoils 51-60 (Win) - one dungeon item'),
(1675636, 1, 2021814, 100, 0, 1, 0, 1, 1, 'Battleground Spoils 10-20 (Loss) - one dungeon item'),
(1675637, 1, 2021814, 100, 0, 1, 0, 1, 1, 'Battleground Spoils 21-30 (Loss) - one dungeon item'),
(1675638, 1, 2021814, 100, 0, 1, 0, 1, 1, 'Battleground Spoils 31-40 (Loss) - one dungeon item'),
(1675639, 1, 2021814, 100, 0, 1, 0, 1, 1, 'Battleground Spoils 41-50 (Loss) - one dungeon item'),
(1675640, 1, 2021814, 100, 0, 1, 0, 1, 1, 'Battleground Spoils 51-60 (Loss) - one dungeon item');
