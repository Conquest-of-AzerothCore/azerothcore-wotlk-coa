-- Graysky's forge (Pale Reach) is part of the map model with no Forge spell focus gameobject, so smelting
-- there failed with "Requires Forge" (#10841). Brokkar Dun, the weaponsmith standing at it, says "Not a bad
-- forge, eh?". Spawn the stock invisible Forge spell focus (30, SpellFocus 3, 4 yd) where the reporter stood.
DELETE FROM `gameobject` WHERE `guid` = 6960213;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960213, 30, 0, 0, 0, 1, 1, -7127.881, 1059.070, 297.945, 0, 0, 0, 0, 1, 0, 0, 1, '', 'Forge spell focus - Graysky forge, Pale Reach');
