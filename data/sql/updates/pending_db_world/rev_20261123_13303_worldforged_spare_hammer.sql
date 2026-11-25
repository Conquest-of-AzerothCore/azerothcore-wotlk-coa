-- #13303: Worldforged Spare Hammer (6940675) floated 0.96 yd above the floor in the middle of Tirion Fordring's house; move it to its first-pass realm x/y from 2026_09_16_00 and onto the measured floor (z 73.778).
UPDATE `gameobject` SET `position_x` = 2671.777, `position_y` = -2488.58, `position_z` = 73.778
WHERE `guid` = 6940675 AND `id` = 96233;
