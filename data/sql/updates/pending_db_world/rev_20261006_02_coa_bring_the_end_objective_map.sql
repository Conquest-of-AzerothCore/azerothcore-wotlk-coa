-- CoA: 3341 'Bring the End' drew its objective marker in Tirisfal Glades instead of Razorfen Downs.
--
-- The quest is finished by handing in 10420 'Skull of the Coldbringer' (RequiredItemId1), which only
-- Amnennar the Coldbringer 7358 drops, and his single spawn (guid 87209) is on Razorfen Downs, map 129,
-- at 2403.37 960.93. The objective row carried those right coordinates but MapID 0 and WorldMapAreaId 20,
-- so the client drew the marker in Tirisfal Glades over Balnir Farmstead, where nothing spawns, and the
-- quest could not be completed by following the map.
--
-- Item objectives take ObjectiveIndex 4 + slot, so this row (ObjectiveIndex 4, RequiredItemId1) already
-- names the right objective; only its map and area change. Map 129's WorldMapArea row is 760 (AreaID 722
-- RazorfenDowns), the same way the row used Tirisfal's 20 (area 85).
--
-- Idempotent: a single keyed UPDATE.

UPDATE `quest_poi` SET `MapID` = 129, `WorldMapAreaId` = 760
WHERE `QuestID` = 3341 AND `id` = 0 AND `ObjectiveIndex` = 4;
