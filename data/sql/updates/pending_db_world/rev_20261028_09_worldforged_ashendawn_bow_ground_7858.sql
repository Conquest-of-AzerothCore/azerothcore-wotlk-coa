-- #7858: Worldforged Ashendawn Bow pickup (guid 6940084, entry 254676, Burning Steppes) sits 1.55 yd
-- under the stock terrain at its own spawn XY (burial confirmed by the reporter). Restore the terrain
-- height 2026_09_23_05_worldforged_map.sql originally placed it at.
UPDATE `gameobject` SET `position_z` = 231.656 WHERE `guid` = 6940084 AND `id` = 254676;
