-- #13341: Worldforged Captain's Spyglass (6941524) lay on the sea floor under water off the Merchant Coast; restore its first-pass realm row from 2026_09_16_00 (ground gap 0.05).
UPDATE `gameobject` SET `position_x` = -1451.82, `position_y` = -3931.74, `position_z` = 3.61
WHERE `guid` = 6941524 AND `id` = 90308;
