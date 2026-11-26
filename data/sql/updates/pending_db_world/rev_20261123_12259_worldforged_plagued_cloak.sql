-- #12259: Worldforged Plagued Cloak (6940892) sank 1.76 yd under the ground at the map-pass point; restore its
-- first-pass realm row from 2026_09_16_00 (ground gap -0.03).
UPDATE `gameobject` SET `position_x` = 1101.53, `position_y` = -1291.74, `position_z` = 62.004
WHERE `guid` = 6940892 AND `id` = 96247;
