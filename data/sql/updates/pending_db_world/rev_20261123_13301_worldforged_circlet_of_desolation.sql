-- #13301: Worldforged Circlet of Desolation (6941569) sat 1.79 yd under the floor; raise it onto the measured floor (z 96.028).
UPDATE `gameobject` SET `position_x` = -422.8, `position_y` = 1121.6, `position_z` = 96.028
WHERE `guid` = 6941569 AND `id` = 254270;
