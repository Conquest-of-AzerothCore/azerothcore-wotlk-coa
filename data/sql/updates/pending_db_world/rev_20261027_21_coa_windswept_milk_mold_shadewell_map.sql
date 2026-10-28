-- Windswept Milk (175074) and Windswept Mold (175075) are given by Grand Cheesemonger Almo at Shadewell Spring. Their
-- objective areas (the Windswept pasture and cave) were only on the Scadeald map (WorldMapAreaId 2062) and their turn-in
-- only on the Shadewell Spring map (2027), so while the player stood in Shadewell Spring the quests had no objective on
-- the map shown: no POI button in the tracker and nothing to track. As quest 21 does for Echo Ridge, each objective area
-- is now also on the Shadewell Spring map and each turn-in also on Scadeald, with the same points.
DELETE FROM `quest_poi` WHERE `QuestID` IN (175074, 175075) AND `id` IN (2, 3);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`) VALUES
(175074, 2, 4, 0, 2027, 0, 0, 1),
(175074, 3, -1, 0, 2062, 0, 0, 1),
(175075, 2, 4, 0, 2027, 0, 0, 1),
(175075, 3, -1, 0, 2062, 0, 0, 1);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (175074, 175075) AND `Idx1` IN (2, 3);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`) VALUES
(175074, 2, 0, -7910, -170), (175074, 2, 1, -7907, -177), (175074, 2, 2, -7877, -196), (175074, 2, 3, -7870, -199),
(175074, 2, 4, -7851, -198), (175074, 2, 5, -7844, -195), (175074, 2, 6, -7841, -188), (175074, 2, 7, -7849, -162),
(175074, 2, 8, -7864, -156), (175074, 2, 9, -7890, -151), (175074, 2, 10, -7897, -154), (175074, 2, 11, -7907, -163),
(175074, 3, 0, -8057, -130), (175075, 2, 0, -7726, -7), (175075, 2, 1, -7723, -14), (175075, 2, 2, -7719, -18),
(175075, 2, 3, -7708, -23), (175075, 2, 4, -7701, -20), (175075, 2, 5, -7687, -2), (175075, 2, 6, -7684, 5),
(175075, 2, 7, -7687, 12), (175075, 2, 8, -7694, 15), (175075, 2, 9, -7710, 9), (175075, 2, 10, -7717, 6),
(175075, 2, 11, -7723, 0), (175075, 3, 0, -8057, -130);
