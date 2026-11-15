-- Worldforged Plague Fiend Chain (pickup 6940887, Eastern Plaguelands) was inside the Crown Guard Tower wall: 0.07 yd from the nearest model, 2.1 yd from the reporter (#11138). Move it to the reporter's standing point (1845.0, -3693.73, 158.109), which the server measures as ground.
UPDATE `gameobject` SET `position_x` = 1845.0, `position_y` = -3693.73, `position_z` = 158.109
WHERE `guid` = 6940887 AND `id` = 90625 AND `map` = 0 AND `position_z` BETWEEN 158.393 AND 158.413 AND `position_x` BETWEEN 1845.190 AND 1845.210 AND `position_y` BETWEEN -3695.810 AND -3695.790;
