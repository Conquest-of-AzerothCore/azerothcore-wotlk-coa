-- Sunken Temple: the Hakkar Worship Altar in the Sanctum of the Fallen God starts the Avatar of Hakkar event
-- without an Egg of Hakkar, as on Ascension.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`) VALUES
(2310500, 10, 7774, 'Hakkar Worship Altar', '', '', 3.5, 0, 0, 0, 3000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'go_hakkar_worship_altar') ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`), `Data3` = VALUES(`Data3`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `gameobject` WHERE `guid` = 4100001;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(4100001, 2310500, 109, 0, 0, 7, 1, -474.5684, 272.73218, -90.41286, 0.016979, 0, 0, 0.008489, 0.999964, 86400, 100, 1, '', 'Hakkar Worship Altar');
