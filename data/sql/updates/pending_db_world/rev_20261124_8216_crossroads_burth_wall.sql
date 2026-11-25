-- Burth (Wildcard event 194), the Crossroads (#8216): the #7212 spot stood 0.6-1.1 yd from the leaning east wall
-- of the patch-WB1 Orchut.wmo hut, so his body showed through it. New spot: the nearest point with at least 1.5 yd
-- vmap clearance at 0.3-2.3 yd height (vmap tile 001_32_36), z on the map-tile terrain, facing away from the hut.
UPDATE `creature` SET `position_x` = -443.847, `position_y` = -2580.061, `position_z` = 96.915, `orientation` = 0.376
WHERE `guid` = 9950044 AND `id` = 342828 AND `position_x` BETWEEN -446.857 AND -446.837
AND `position_y` BETWEEN -2583.071 AND -2583.051;
