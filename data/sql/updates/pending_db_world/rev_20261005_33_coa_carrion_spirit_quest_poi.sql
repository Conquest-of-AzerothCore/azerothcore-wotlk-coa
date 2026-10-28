-- Fighting Over Carrion (1660043): the objective area follows the Cruel Carrion Spirit's flight circle around
-- (-3592, -1074) instead of its first spawn at (-3509, -1105).
DELETE FROM `quest_poi_points` WHERE `QuestID` = 1660043 AND `Idx1` = 0;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`) VALUES
(1660043, 0, 0, -3572, -1074),
(1660043, 0, 1, -3578, -1060),
(1660043, 0, 2, -3592, -1054),
(1660043, 0, 3, -3606, -1060),
(1660043, 0, 4, -3612, -1074),
(1660043, 0, 5, -3606, -1088),
(1660043, 0, 6, -3592, -1094),
(1660043, 0, 7, -3578, -1088);
