-- Issue #7722 follow-up: the world map draws no area for quest 1195 'The Sacred Flame' because its area row
-- targets an objective slot the quest does not own; the in-world arrow is already fixed by rev_20261015_02.
--
-- WHERE EACH VALUE COMES FROM
--   the area row  SOURCED-CORE: quest_poi 1195/1 is the stock area (Flags 1, eight points) but carries
--     ObjectiveIndex 10, which addresses item objective slot 6, empty for this quest (RequiredItemId1-6 are 0).
--     quest_poi 1195/2 carries ObjectiveIndex 5, the objective the client already draws as the pin at
--     1888 -1776, which the issue reports as the map's correct location, so the area joins that objective.
--   the ring  SOURCED-CORE: gameobject 20806 'Ashenvale Moonwell' at (1870.43, -1771.57, 61.328); DERIVED:
--     eight points on a 14 yd ring, the moonwell's visible footprint, rounded to the integer world yards the
--     table stores.
--   blast radius  quest_poi rows are keyed by quest, so only 1195 gains the area. its turn-in row 1195/0
--     (Zangen Stonehoof, -1208 -57) and its pin row 1195/2 are untouched.
UPDATE `quest_poi` SET `ObjectiveIndex` = 5 WHERE `QuestID` = 1195 AND `id` = 1;
DELETE FROM `quest_poi_points` WHERE `QuestID` = 1195 AND `Idx1` = 1;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`) VALUES
(1195, 1, 0, 1884, -1772),
(1195, 1, 1, 1880, -1762),
(1195, 1, 2, 1870, -1758),
(1195, 1, 3, 1861, -1762),
(1195, 1, 4, 1856, -1772),
(1195, 1, 5, 1861, -1781),
(1195, 1, 6, 1870, -1786),
(1195, 1, 7, 1880, -1781);
