-- #12350: Worldforged Wailing Spirit Amulet (6941317) was 5 yd under the ground at the map-pass point; restore its
-- first-pass realm row from 2026_09_16_00 (ground gap -0.39).
UPDATE `gameobject` SET `position_x` = 2214.19, `position_y` = -2926.46, `position_z` = 110.254
WHERE `guid` = 6941317 AND `id` = 90627;
