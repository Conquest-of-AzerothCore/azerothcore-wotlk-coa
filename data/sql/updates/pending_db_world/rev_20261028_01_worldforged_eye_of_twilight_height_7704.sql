-- #7704: Worldforged Eye of Twilight (guid 6940452, entry 158333, Searing Gorge) sits 6.8 yd above the
-- ground its own spawn XY lands on, out of interaction reach. Restore the stock terrain height that
-- 2026_09_23_05_worldforged_map.sql placed it at before 2026_09_23_06_worldforged_recorded_heights.sql
-- lifted it to an unreachable client sighting.
UPDATE `gameobject` SET `position_z` = 287.094 WHERE `guid` = 6940452 AND `id` = 158333;
