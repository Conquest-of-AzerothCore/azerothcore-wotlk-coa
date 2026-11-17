UPDATE `quest_poi_points` SET `X` = -8408, `Y` = 214 WHERE (`QuestID`, `Idx1`, `Idx2`) = (563, 0, 0);

DELETE FROM `coa_client_super_track` WHERE `ID` = 1318;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(1318, 0, -8407.6, 214.4, 155.347, 5.5, 0, 0);
