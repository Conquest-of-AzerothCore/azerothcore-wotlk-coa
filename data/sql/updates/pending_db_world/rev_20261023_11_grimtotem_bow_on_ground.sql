-- Worldforged Grimtotem Bow (520699, guid 6941796) at Three Totems, Mulgore: back on the ground where it was placed in game
-- (rev_20261004_20_coa_mulgore_three_totems_placement.sql). rev_20261014_95_worldforged_lootcollector_alignment.sql moved it
-- to z 220.811, about 16 yd above the ground, out of reach.
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`,
    `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`,
    `state`, `ScriptName`, `Comment`) VALUES
(6941796, 520699, 1, 0, 0, 1, 1, -3641.917, -1032.398, 204.614, 0.546,
    -0.7376661, -0.2065396, 0.1733124, 0.6189936, 300, 0, 1, 'worldforged_pickup',
    'CoA Three Totems: Worldforged Grimtotem Bow on the ground, placed in game')
ON DUPLICATE KEY UPDATE `position_x` = VALUES(`position_x`), `position_y` = VALUES(`position_y`),
    `position_z` = VALUES(`position_z`), `orientation` = VALUES(`orientation`), `rotation0` = VALUES(`rotation0`),
    `rotation1` = VALUES(`rotation1`), `rotation2` = VALUES(`rotation2`), `rotation3` = VALUES(`rotation3`);
