-- #12477: Worldforged Stolen Belt (6941146) clipped into the lower Dreadmaul Rock cavern floor; restore its
-- first-pass realm x/y from 2026_09_16_00 at the recorded height 124.225 (ground gap -0.04).
UPDATE `gameobject` SET `position_x` = -7853.72, `position_y` = -2640.02 WHERE `guid` = 6941146 AND `id` = 254648;
