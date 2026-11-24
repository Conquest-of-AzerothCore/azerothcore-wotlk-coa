-- #13388: Worldforged Skippy's Bone (6941091) floated 2.96 yd above the ground; restore its first-pass realm row from 2026_09_16_00 (ground gap -0.05).
UPDATE `gameobject` SET `position_x` = 1375.61, `position_y` = -1119.19, `position_z` = 53.088
WHERE `guid` = 6941091 AND `id` = 324495;
