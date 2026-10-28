-- CoA: 62 'The Fargodeep Mine' was pinning its objective at the north-west mine instead
-- of the Fargodeep Mine south of Goldshire (where the sibling Kobold Candles and Gold
-- Dust Exchange markers sit). Move the six objective points onto the same southern mine
-- grounds, matching quest 60's objective cluster.
UPDATE `quest_poi_points` SET `X` = -9317, `Y` = -717 WHERE (`QuestID`, `Idx1`, `Idx2`) = (62, 0, 0);
UPDATE `quest_poi_points` SET `X` = -9240, `Y` = -714 WHERE (`QuestID`, `Idx1`, `Idx2`) = (62, 0, 1);
UPDATE `quest_poi_points` SET `X` = -9080, `Y` = -587 WHERE (`QuestID`, `Idx1`, `Idx2`) = (62, 0, 2);
UPDATE `quest_poi_points` SET `X` = -9088, `Y` = -557 WHERE (`QuestID`, `Idx1`, `Idx2`) = (62, 0, 3);
UPDATE `quest_poi_points` SET `X` = -9283, `Y` = -554 WHERE (`QuestID`, `Idx1`, `Idx2`) = (62, 0, 4);
UPDATE `quest_poi_points` SET `X` = -9318, `Y` = -584 WHERE (`QuestID`, `Idx1`, `Idx2`) = (62, 0, 5);
