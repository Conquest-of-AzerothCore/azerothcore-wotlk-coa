-- The forges of Stromgarde Keep (Arathi Highlands) are part of the map model with no Forge spell focus
-- gameobject, so smelting there failed with "Requires Forge" (#11771). Spawn the stock invisible Forge spell
-- focus (30, SpellFocus 3, 4 yd) where the reporter stood.
DELETE FROM `gameobject` WHERE `guid` = 6960215;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960215, 30, 0, 0, 0, 1, 1, -1647.980, -1652.092, 69.675, 0, 0, 0, 0, 1, 0, 0, 1, '', 'Forge spell focus - Stromgarde Keep forge');
