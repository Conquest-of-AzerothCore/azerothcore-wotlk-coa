-- Broken Alliances (782): Boss Tho'grun (creature 2944, guid 7209) walks a ~20 minute patrol (path 72090) between
-- the Dustbelcher camps, but the map showed a single point at Camp Boff, which he only passes for a moment.
-- The objective area now covers his spawn and every point of the patrol, 40 yd margin, in 12 points: the client
-- crashes drawing the map when an area has more (24 did; sniffed areas never exceed 12).
DELETE FROM `quest_poi_points` WHERE `QuestID` = 782 AND `Idx1` = 1;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`) VALUES
(782, 1, 0, -7152, -3333),
(782, 1, 1, -7118, -3582),
(782, 1, 2, -7065, -3655),
(782, 1, 3, -6986, -3635),
(782, 1, 4, -6672, -3381),
(782, 1, 5, -6656, -3298),
(782, 1, 6, -6815, -2543),
(782, 1, 7, -6942, -2381),
(782, 1, 8, -7026, -2326),
(782, 1, 9, -7121, -2327),
(782, 1, 10, -7218, -2402),
(782, 1, 11, -7235, -2541);
