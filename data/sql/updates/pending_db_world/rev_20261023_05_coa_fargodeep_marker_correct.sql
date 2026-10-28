-- CoA #8695: quest 62 'The Fargodeep Mine' map guide points at Jasperlode.
-- rev_20261019_31 moved the six objective points into the Jasperlode cluster;
-- these are the Fargodeep points south of Goldshire, confirmed in game.
UPDATE `quest_poi_points` SET `X` = -9844, `Y` = 92 WHERE (`QuestID`, `Idx1`, `Idx2`) = (62, 0, 0);
UPDATE `quest_poi_points` SET `X` = -9796, `Y` = 122 WHERE (`QuestID`, `Idx1`, `Idx2`) = (62, 0, 1);
UPDATE `quest_poi_points` SET `X` = -9760, `Y` = 158 WHERE (`QuestID`, `Idx1`, `Idx2`) = (62, 0, 2);
UPDATE `quest_poi_points` SET `X` = -9796, `Y` = 194 WHERE (`QuestID`, `Idx1`, `Idx2`) = (62, 0, 3);
UPDATE `quest_poi_points` SET `X` = -9844, `Y` = 164 WHERE (`QuestID`, `Idx1`, `Idx2`) = (62, 0, 4);
UPDATE `quest_poi_points` SET `X` = -9880, `Y` = 128 WHERE (`QuestID`, `Idx1`, `Idx2`) = (62, 0, 5);
