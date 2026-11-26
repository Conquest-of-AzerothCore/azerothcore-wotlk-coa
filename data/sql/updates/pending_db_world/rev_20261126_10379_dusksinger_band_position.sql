-- Worldforged Dusksinger Band (entry 254392, guid 6940389, Stonard): 2026_09_23_05_worldforged_map moved it 5.0 yd
-- south-west off the Taurenlogchair02 table (floor 22.0128) onto bare Swamporcgreathall floor (20.9641) while keeping
-- z = 22.032, leaving it floating 1.07 yd in the air (#10379). Restore first-pass realm-dump row 6900168.
UPDATE `gameobject`
SET `position_x` = -10461.500, `position_y` = -3316.340, `position_z` = 22.032,
    `orientation` = 1.45448, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.664809, `rotation3` = 0.747013
WHERE `guid` = 6940389 AND `id` = 254392 AND `map` = 0;
