-- Dar'Khan's Lieutenants (9170): mark Masophet the Black's second pooled spawn (pool 373, guid 152293)
DELETE FROM `quest_poi` WHERE `QuestID` = 9170 AND `id` = 5;
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
VALUES
(9170, 5, 3, 530, 463, 0, 0, 1, 0);

DELETE FROM `quest_poi_points` WHERE `QuestID` = 9170 AND `Idx1` = 5;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(9170, 5, 0, 6311, -6250, 0);
