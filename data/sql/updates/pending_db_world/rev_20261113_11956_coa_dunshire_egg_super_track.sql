DELETE FROM `coa_client_super_track` WHERE `ID` = 21064;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(21064, 0, -7815.85, 545.566, 136.357, 4, 0, 0);

DELETE FROM `coa_client_quest_super_track` WHERE `ID` = 32929;
INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`, `AllowableRaces`) VALUES
(32929, 175030, 0, 0, 9177, 0),
(32929, 175030, 2, 0, 21064, 0),
(32929, 175030, -1, 0, 9114, 0);
