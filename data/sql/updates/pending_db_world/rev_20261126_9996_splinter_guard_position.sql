-- Splinter Guard (#9996): rev_20261006_65_worldforged_openworld_float_heights.sql lowered
-- guid 6941135 (entry 95749) onto bare terrain (z 11.423), 1.98 yd below the Westfall_Lumbermill.wmo
-- floor (z 13.3983) at (-11987.7, -541.9). Restore the authoritative first-pass realm-dump
-- coordinates from 2026_09_16_00_worldforged_pickups.sql (row 6901172) on the lumbermill floor
-- (z 14.043, WMO floor 14.0886).

UPDATE `gameobject`
SET `position_x` = -11986.000, `position_y` = -540.594, `position_z` = 14.043
WHERE `guid` = 6941135 AND `id` = 95749 AND `map` = 0;
