-- Sins Beyond Mercy (175200) had no map markers or tracker point (#11979): it was left out of the Pale Reach marker
-- pass, and the client has no SuperTrack point for it, so its markers come from quest_poi alone. One point for each
-- target (Brother Aldren, Paladin Abigail, and Samuel Crowe at the middle of his walk) and the turn-in at Confessor
-- Mourn.
DELETE FROM `quest_poi` WHERE `QuestID` = 175200;
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`) VALUES
(175200, 0, 0, 0, 2062, 0, 0, 1),
(175200, 1, 1, 0, 2062, 0, 0, 1),
(175200, 2, 2, 0, 2062, 0, 0, 1),
(175200, 3, -1, 0, 2062, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE `QuestID` = 175200;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`) VALUES
(175200, 0, 0, -6939, 1774),
(175200, 1, 0, -6855, 1654),
(175200, 2, 0, -6962, 1731),
(175200, 3, 0, -6911, 1725);
