-- CoA Coldridge class chain: The Stolen Power Core (200090) gets the markers the world map draws for it - the
-- two Burly Rockjaw Trogg areas and the turn-in pin. The quest had no `quest_poi` row at all, so a player
-- carrying it saw a completely unmarked map (#5912).
--
-- 200090 is an item objective: it wants the Power Core 661417 (RequiredItemId1), which only Burly Rockjaw
-- Trogg 724 drops (creature_loot_template 724/661417, QuestRequired, rev_20260923_07). Item objectives take
-- ObjectiveIndex 4, the first item slot, the way rev_20261007_80 marks 200058 Lost Pendant.
--
-- The areas are not drawn by hand: they are the two Burly Rockjaw Trogg areas the sniffed stock quest 170
-- 'A New Threat' already carries for its RequiredNpcOrGo2 724 objective (base quest_poi.sql:475-476, ids 2
-- and 3 on ObjectiveIndex 1, map 0, WorldMapAreaId 27 Dun Morogh, Floor 0, Priority 0, Flags 1; points in
-- base quest_poi_points.sql:1835-1849). They cover the troggs' southern ground around -6360 300 and the
-- northern ground from -6250 460 to -6480 840, where the 61 spawns of 724 stand.
--
-- The turn-in pin is a single point on Binkle Coldbolt (502870, guid 9003309 at -6116.33 396.93,
-- rev_20260923_07), who both starts and ends the quest, the way rev_20261007_80 pins its trainers.
--
-- Idempotent: delete of the exact keys followed by the insert.

DELETE FROM `quest_poi` WHERE `QuestID` = 200090 AND `id` IN (0, 1, 2);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(200090, 0, 4, 0, 27, 0, 0, 1),
(200090, 1, 4, 0, 27, 0, 0, 1),
(200090, 2, -1, 0, 27, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE `QuestID` = 200090 AND `Idx1` IN (0, 1, 2);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(200090, 0, 0, -6361, 203),
(200090, 0, 1, -6299, 243),
(200090, 0, 2, -6340, 359),
(200090, 0, 3, -6390, 436),
(200090, 0, 4, -6437, 396),
(200090, 0, 5, -6404, 236),
(200090, 1, 0, -6270, 456),
(200090, 1, 1, -6247, 464),
(200090, 1, 2, -6238, 490),
(200090, 1, 3, -6186, 778),
(200090, 1, 4, -6245, 842),
(200090, 1, 5, -6322, 841),
(200090, 1, 6, -6419, 818),
(200090, 1, 7, -6484, 616),
(200090, 1, 8, -6286, 459),
(200090, 2, 0, -6116, 397);
