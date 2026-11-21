DELETE FROM `quest_poi` WHERE `QuestID` = 1660012 AND `id` = 2;
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`) VALUES
(1660012, 2, 1, 1, 41, 0, 0, 1);
DELETE FROM `quest_poi_points` WHERE `QuestID` = 1660012 AND `Idx1` = 2;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`) VALUES
(1660012, 2, 0, 10707, 617),
(1660012, 2, 1, 10707, 577),
(1660012, 2, 2, 10667, 577),
(1660012, 2, 3, 10667, 617);
