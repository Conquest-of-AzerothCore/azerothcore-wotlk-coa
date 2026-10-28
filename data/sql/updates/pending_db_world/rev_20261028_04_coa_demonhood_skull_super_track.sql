-- Coming into Demonhood (200021 Skull of L'ok, 200022 Skull of Kaz) had no QuestSuperTrack row, so the client fell
-- back to the quest's map area at height 0 and the quest diamond drifted up and down with the player. Each quest now
-- tracks its two skulls and, for the turn-in, Flowzie the Fel-Touched or Grillok Morzog. The nodes use unused IDs
-- inside the client's SuperTrack range.
DELETE FROM `coa_client_super_track` WHERE `ID` BETWEEN 18632 AND 18637;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(18632, 1, -594, -4135, 46.26, 5.5, 0, 0),
(18633, 1, -596, -4145, 47.26, 5.5, 0, 0),
(18634, 1, -584.87, -4125.95, 43.85, 5.5, 0, 0),
(18635, 1, 10362, 749.5, 1321.84, 5.5, 0, 0),
(18636, 1, 10371, 737, 1323.46, 5.5, 0, 0),
(18637, 1, 10345.4, 757.2, 1326.45, 5.5, 0, 0);

DELETE FROM `coa_client_quest_super_track` WHERE `ID` IN (33420, 33421);
INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`, `AllowableRaces`) VALUES
(33420, 200022, 0, 0, 18632, 0),
(33420, 200022, 0, 1, 18633, 0),
(33420, 200022, -1, 0, 18634, 0),
(33421, 200021, 0, 0, 18635, 0),
(33421, 200021, 0, 1, 18636, 0),
(33421, 200021, -1, 0, 18637, 0);
