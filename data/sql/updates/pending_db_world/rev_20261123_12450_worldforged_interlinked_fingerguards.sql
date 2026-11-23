-- #12450: Worldforged Interlinked Fingerguards (6940655) was 21 yd from where the reporter searched; restore its
-- first-pass realm row from 2026_09_16_00, 3.2 yd from the reporter's position.
UPDATE `gameobject` SET `position_x` = -1591.85, `position_y` = -2538.9, `position_z` = 42.218
WHERE `guid` = 6940655 AND `id` = 95862;
