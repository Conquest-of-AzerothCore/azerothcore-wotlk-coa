-- The Half-Detailed Report (#7685): the client turn-in arrow for 999914 (QuestSuperTrack node
-- 21335) sits about six yards off the ender. Put it exactly on Archivist Selnor's spawn so the
-- arrow is on top of her when the player returns with the report. Node 21335 is used only by
-- this quest.

DELETE FROM `coa_client_super_track` WHERE `ID` = 21335;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(21335, 0, -10679.3, 957.9, 38.47, 5.5, 0, 0);
