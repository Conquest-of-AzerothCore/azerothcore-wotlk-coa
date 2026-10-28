-- Durnholde Keep: patch-WB1 replaced the barracks with WESTFALL_BARRACKS.WMO, which left the Solid Chest (2850,
-- guid 30018) inside a wall. It moves to the long-table room beside the candelabra, at the spot set in game.
UPDATE `gameobject` SET `position_x` = -447.3544, `position_y` = -1470.2145, `position_z` = 89.46,
    `orientation` = 5.7108, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.2823, `rotation3` = -0.9593
    WHERE `guid` = 30018 AND `id` = 2850;
