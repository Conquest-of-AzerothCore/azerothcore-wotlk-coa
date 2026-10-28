-- Item objectives are numbered 4..9 on the client: the four NPC/GO slots come first.
-- Stock data proves it (quest 2 -> index 4, quest 38 -> 4,5,6, quest 2478 -> 4,5,6).
-- Our three item requirements are therefore 4, 5, 6, not 0, 1, 2.
UPDATE `quest_poi` SET `ObjectiveIndex` = 4 WHERE `QuestID` IN (17839, 17844) AND `id` = 0;
UPDATE `quest_poi` SET `ObjectiveIndex` = 5 WHERE `QuestID` IN (17839, 17844) AND `id` = 1;
UPDATE `quest_poi` SET `ObjectiveIndex` = 6 WHERE `QuestID` IN (17839, 17844) AND `id` = 2;

-- The super track row has five node slots: 0..3 for the NPC/GO objectives and slot 4
-- for the first item objective, which is where stock item quests keep their nodes
-- (quest 2 keeps its only node in slot 4). The loader maps objective -1 onto slot 4.
DELETE FROM `coa_client_quest_super_track` WHERE `ID` IN (10130, 10133, 33214, 33215);

INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`) VALUES
(10130, 17839, -1, 0, 21505),
(10130, 17839, -1, 1, 21508),
(10130, 17839, -1, 2, 21523),
(10133, 17844, -1, 0, 21505),
(10133, 17844, -1, 1, 21508),
(10133, 17844, -1, 2, 21523);
