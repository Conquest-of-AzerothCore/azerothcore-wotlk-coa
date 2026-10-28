-- Lost Mountaineer's Bow (#8913): rev_20261014_95 moved a copy (6960033) into Coldridge Pass, standing upright in
-- the ground beside the Coldridge one. The copy has no source as a Duskwood find (a level 7 bow) and goes; the
-- Coldridge pickup lies at the realm client's sighting, as placed in game.
DELETE FROM `gameobject` WHERE `guid` = 6960033 AND `id` = 95507;

DELETE FROM `gameobject` WHERE `guid` = 6940723;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`,
    `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`,
    `state`, `ScriptName`, `Comment`) VALUES
(6940723, 95507, 0, 0, 0, 1, 1, -5927.594, 19.061, 365.638, 1.328, 0.5373256, 0.4596554, 0.4110545, 0.5753542, 0, 0,
    1, 'worldforged_pickup', 'Worldforged Lost Mountaineer''s Bow | realm map Dun Morogh');
