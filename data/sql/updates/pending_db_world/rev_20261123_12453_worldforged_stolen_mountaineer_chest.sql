-- #12453: Worldforged Stolen Mountaineer Chest (6941151) was 4.39 yd under the ground at the map-pass point;
-- restore its first-pass realm row from 2026_09_16_00 (ground gap -0.08).
UPDATE `gameobject` SET `position_x` = -5898.9, `position_y` = -2955.43, `position_z` = 367.932
WHERE `guid` = 6941151 AND `id` = 517340;
