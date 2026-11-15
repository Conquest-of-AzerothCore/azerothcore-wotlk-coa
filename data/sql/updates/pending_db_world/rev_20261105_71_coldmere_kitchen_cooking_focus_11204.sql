-- The kitchen fires of Coldmere Keep (Pale Reach) are part of the map model with no Cooking Fire spell focus
-- gameobject, so cooking there failed with "Requires Cooking Fire" (#11204). Add a server-only invisible
-- Cooking Fire focus (SpellFocus 4, 10 yd) where the reporter stood. Stock 181377 links a damage trap and 184911 and
-- 186249 run go_flames, which burns players standing on them, so the focus gets a template of its own.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2399002, 8, 0, 'Cooking Fire Spell Focus', '', '', '', 1, 4, 10, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);
DELETE FROM `gameobject` WHERE `guid` = 6960214;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960214, 2399002, 0, 0, 0, 1, 1, -7223.05, 1234.69, 328.5, 0, 0, 0, 0, 1, 0, 0, 1, '', 'Cooking Fire spell focus - Coldmere Keep kitchen, Pale Reach');
