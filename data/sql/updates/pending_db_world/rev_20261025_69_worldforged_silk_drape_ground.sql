-- jealous-sound/azerothcore-wotlk-coa#9146: the Worldforged Silk Drape (95535, guid 6901050) in Dalaran Crater,
-- Alterac, floats out of reach on the PTR. Pin it to the spot a player reported in game, on the ground.
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`,
    `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`,
    `state`, `ScriptName`, `Comment`) VALUES
(6901050, 95535, 0, 0, 0, 1, 1, 307.660, 174.979, 47.629, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup',
    'AscensionWorldforged Silk Drape | Dalaran Crater, on the ground where it was reported in game')
ON DUPLICATE KEY UPDATE `position_x` = VALUES(`position_x`), `position_y` = VALUES(`position_y`),
    `position_z` = VALUES(`position_z`), `orientation` = VALUES(`orientation`), `rotation0` = VALUES(`rotation0`),
    `rotation1` = VALUES(`rotation1`), `rotation2` = VALUES(`rotation2`), `rotation3` = VALUES(`rotation3`),
    `Comment` = VALUES(`Comment`);
