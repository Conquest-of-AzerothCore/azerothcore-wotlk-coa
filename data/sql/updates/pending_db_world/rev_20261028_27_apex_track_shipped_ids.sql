-- The client cannot gain a QuestSuperTrack row at runtime: that table's patch has no
-- rebuild hook, so only rows already in its file are consulted. So the quests move
-- onto ids the client already tracks: 17839 (Alliance) and 17844 (Horde), each with
-- rows for objectives 0,1,2 whose nodes are 7301/7302/7303 and 7309/7310/7311.
-- We overwrite those node rows with the patrol positions instead.

-- restore CoA's own row that an earlier revision deleted
DELETE FROM `coa_client_quest_super_track` WHERE `ID` = 33213;
INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`) VALUES
(33213, 9915004, -1, 0, 21110),
(33213, 9915004, 0, 0, 21111), (33213, 9915004, 0, 1, 21112),
(33213, 9915004, 1, 0, 21113), (33213, 9915004, 1, 1, 21114),
(33213, 9915004, 2, 0, 21115), (33213, 9915004, 2, 1, 21116);

-- our own inserted rows are useless to the client
DELETE FROM `coa_client_quest_super_track` WHERE `ID` IN (33214, 33215);

-- nodes the shipped rows point at, moved onto the three patrols
DELETE FROM `coa_client_super_track` WHERE `ID` IN (7301, 7302, 7303, 7309, 7310, 7311);
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(7301, 1, 2267.21, -6787.11, 125.24, 5.5, 0, 0),
(7302, 0, 138.558, -4523.49, 126.401, 5.5, 0, 0),
(7303, 1, -3887.07, 1958.59, 75.3706, 5.5, 0, 0),
(7309, 1, 2267.21, -6787.11, 125.24, 5.5, 0, 0),
(7310, 0, 138.558, -4523.49, 126.401, 5.5, 0, 0),
(7311, 1, -3887.07, 1958.59, 75.3706, 5.5, 0, 0);

-- move the quests onto the tracked ids
UPDATE quest_template SET ID = 17839 WHERE ID = 9916201
  AND NOT EXISTS (SELECT 1 FROM (SELECT ID FROM quest_template WHERE ID = 17839) x);
UPDATE quest_template SET ID = 17844 WHERE ID = 9916211
  AND NOT EXISTS (SELECT 1 FROM (SELECT ID FROM quest_template WHERE ID = 17844) x);

UPDATE `creature_queststarter` SET `quest` = 17839 WHERE `quest` = 9916201;
UPDATE `creature_queststarter` SET `quest` = 17844 WHERE `quest` = 9916211;
UPDATE `creature_questender`  SET `quest` = 17839 WHERE `quest` = 9916201;
UPDATE `creature_questender`  SET `quest` = 17844 WHERE `quest` = 9916211;

UPDATE quest_poi SET QuestID = 17839 WHERE QuestID = 9916201
  AND NOT EXISTS (SELECT 1 FROM (SELECT QuestID FROM quest_poi WHERE QuestID = 17839) x);
UPDATE quest_poi_points SET QuestID = 17839 WHERE QuestID = 9916201
  AND NOT EXISTS (SELECT 1 FROM (SELECT QuestID FROM quest_poi_points WHERE QuestID = 17839) x);
UPDATE quest_poi SET QuestID = 17844 WHERE QuestID = 9916211
  AND NOT EXISTS (SELECT 1 FROM (SELECT QuestID FROM quest_poi WHERE QuestID = 17844) x);
UPDATE quest_poi_points SET QuestID = 17844 WHERE QuestID = 9916211
  AND NOT EXISTS (SELECT 1 FROM (SELECT QuestID FROM quest_poi_points WHERE QuestID = 17844) x);
