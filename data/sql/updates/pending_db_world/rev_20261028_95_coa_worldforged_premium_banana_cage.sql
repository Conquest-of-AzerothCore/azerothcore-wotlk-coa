-- Worldforged Premium Banana: the realm's Baby Gorilla Bait (95715) is its own invisible chest inside a
-- Cage Prop (95982, display 1017068); both are recorded 0.7 yd apart at the Spirit Den mouth and match
-- footage of the pickup. Positions set in game against that footage.

UPDATE `gameobject_template` SET `displayId` = 980926, `castBarCaption` = 'Looting' WHERE `entry` = 95715;

REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(95982, 5, 1017068, 'Cage Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');

UPDATE `gameobject`
SET `position_x` = -13758.899, `position_y` = -11.389, `position_z` = 45.888, `orientation` = 1.0484,
    `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.500521, `rotation3` = 0.865725
WHERE `guid` = 6940909 AND `id` = 95715;

DELETE FROM `gameobject` WHERE `guid` = 6960212;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960212, 95982, 0, 0, 0, 1, 1, -13758.966, -10.940, 45.316, 2.4447, 0, 0, 0.939904, 0.341438, 0, 0, 1, '', 'Cage Prop - Baby Gorilla Bait companion, Spirit Den');
