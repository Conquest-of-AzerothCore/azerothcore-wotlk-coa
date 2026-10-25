-- Lost Mountaineer's Bow (#8913): rev_20261014_95 moved the Duskwood Pass copy (6960033) into Coldridge Pass,
-- standing upright in the ground beside the Coldridge one. Return it to its authored Duskwood spot and keep the
-- Coldridge pickup (6940723) flat at the realm client's sighting.
UPDATE `gameobject` SET `position_x` = -10923.5625, `position_y` = -381.177734, `position_z` = 39.483627,
    `orientation` = 0.217579, `rotation0` = 0.107119026, `rotation1` = 0.648251995, `rotation2` = 0.081849561,
    `rotation3` = 0.749396767
WHERE `guid` = 6960033 AND `id` = 95507;

DELETE FROM `gameobject` WHERE `guid` = 6940723;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`,
    `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`,
    `state`, `ScriptName`, `Comment`) VALUES
(6940723, 95507, 0, 0, 0, 1, 1, -5927.34, 18.562, 366.192, 5.60403, 0, 0, 0.333089, -0.942895, 0, 0, 1,
    'worldforged_pickup', 'Worldforged Lost Mountaineer''s Bow | realm map Dun Morogh');
