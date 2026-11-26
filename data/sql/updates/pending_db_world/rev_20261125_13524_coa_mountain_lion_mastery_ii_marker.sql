-- Mountain Lion Mastery II (1331): estimated objective area over the 18 Feral Mountain Lion (2385) spawns in
-- Hillsbrad Foothills. The client has no QuestSuperTrack row for 1331, so rev_20261027_85 gave it only the turn-in pin.
DELETE FROM `quest_poi` WHERE `QuestID` = 1331 AND `id` = 1;
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`,
    `Flags`) VALUES
(1331, 1, 0, 0, 24, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE `QuestID` = 1331 AND `Idx1` = 1;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`) VALUES
(1331, 1, 0, -1326, -747),
(1331, 1, 1, -666, -747),
(1331, 1, 2, -666, -1185),
(1331, 1, 3, -1326, -1185);
