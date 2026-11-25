-- #13398: Worldforged Libram of Remembrance (6940702) floated 0.46 yd above the ground; restore its first-pass realm x/y from 2026_09_16_00 (ground gap 0.01).
UPDATE `gameobject` SET `position_x` = 1021.28, `position_y` = -1817.32, `position_z` = 77.726
WHERE `guid` = 6940702 AND `id` = 324510;
