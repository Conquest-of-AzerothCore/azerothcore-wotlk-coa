-- Lost Pendant (200058): the objective marker sat 39 yd from the pendant. rev_20261007_80 drew the quest's search
-- area as a 95 x 95 yd rectangle around the whole Defias camp (-9035..-8940, -460..-365), and the client puts the
-- yellow diamond at the centre of that area, (-8987, -412), not on the chest. The pendant (gameobject 9301103,
-- guid 7912105) stands on the crate at -8956.38 -435.027. The rectangle is now 50 x 50 yd centred on it, so the
-- diamond lands on the crate (-8956, -435).
UPDATE `quest_poi_points` SET `X` = -8981, `Y` = -460 WHERE `QuestID` = 200058 AND `Idx1` = 0 AND `Idx2` = 0;
UPDATE `quest_poi_points` SET `X` = -8931, `Y` = -460 WHERE `QuestID` = 200058 AND `Idx1` = 0 AND `Idx2` = 1;
UPDATE `quest_poi_points` SET `X` = -8931, `Y` = -410 WHERE `QuestID` = 200058 AND `Idx1` = 0 AND `Idx2` = 2;
UPDATE `quest_poi_points` SET `X` = -8981, `Y` = -410 WHERE `QuestID` = 200058 AND `Idx1` = 0 AND `Idx2` = 3;
