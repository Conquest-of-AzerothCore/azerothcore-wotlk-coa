-- Windswept Mold (175075): Fresh Mold (2300683) is 9prg_mosshanging_a01, which hangs from its origin, about 4.85 yd
-- of moss at size 1. Set 6 yd over the floor, each mold hung in mid-air 2-6 yd under the roof of the Windswept Cave.
-- On the realm the mold hangs from the roof and rock faces and is gathered from below (SGUWwezq2Z0 59:34-59:52,
-- hxdp8nA91RA 2:14:44-2:14:56). As for Dark Moss, each mold is two objects: a plain strand at 1.15 hung from the
-- roof of Md_Mushroomden, and the collectable Fresh Mold as an invisible cube on the strand's lower end, never over
-- 4.3 yd up. The roof stands 12-15 yd over the middle of the chamber, so the molds move up to 4.5 yd towards the walls
-- and the passage, where a strand reaches down that far. Collecting the cube takes the strand away with it, and both
-- return after 90 s.
UPDATE `gameobject_template` SET `displayId` = 980926, `size` = 3, `AIName` = 'SmartGameObjectAI' WHERE `entry` = 2300683;
UPDATE `gameobject` SET `position_x` = -7718, `position_y` = -11, `position_z` = 423.95, `Comment` = 'Fresh Mold, Windswept Cave, under hanging mold 9993100' WHERE `guid` = 9999000 AND `id` = 2300683;
UPDATE `gameobject` SET `position_x` = -7710.5, `position_y` = -13, `position_z` = 422.34, `Comment` = 'Fresh Mold, Windswept Cave, under hanging mold 9993101' WHERE `guid` = 9999001 AND `id` = 2300683;
UPDATE `gameobject` SET `position_x` = -7705.5, `position_y` = -14.5, `position_z` = 421.69, `Comment` = 'Fresh Mold, Windswept Cave, under hanging mold 9993102' WHERE `guid` = 9999002 AND `id` = 2300683;
UPDATE `gameobject` SET `position_x` = -7714, `position_y` = -2.5, `position_z` = 423.02, `Comment` = 'Fresh Mold, Windswept Cave, under hanging mold 9993103' WHERE `guid` = 9999003 AND `id` = 2300683;
UPDATE `gameobject` SET `position_x` = -7700.5, `position_y` = 1, `position_z` = 422.19, `Comment` = 'Fresh Mold, Windswept Cave, under hanging mold 9993104' WHERE `guid` = 9999004 AND `id` = 2300683;
UPDATE `gameobject` SET `position_x` = -7691.5, `position_y` = 4, `position_z` = 421.01, `Comment` = 'Fresh Mold, Windswept Cave, under hanging mold 9993105' WHERE `guid` = 9999005 AND `id` = 2300683;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data8`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(2399012, 5, 1075822, 'Hanging Mold', '', '', '', 1.15, 0, 0, 0, 0, 0, 0, 0, '', '', 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`);
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9993100 AND 9993105;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9993100, 2399012, 0, 0, 0, 1, 1, -7718, -11, 429.94, 6.022, 0, 0, 0.130424, -0.991458, 90, 100, 1, 'Pale Reach: hanging mold over Fresh Mold 9999000'),
(9993101, 2399012, 0, 0, 0, 1, 1, -7710.5, -13, 427.92, 0.524, 0, 0, 0.259013, 0.965874, 90, 100, 1, 'Pale Reach: hanging mold over Fresh Mold 9999001'),
(9993102, 2399012, 0, 0, 0, 1, 1, -7705.5, -14.5, 427.27, 1.833, 0, 0, 0.793476, 0.608601, 90, 100, 1, 'Pale Reach: hanging mold over Fresh Mold 9999002'),
(9993103, 2399012, 0, 0, 0, 1, 1, -7714, -2.5, 428.87, 5.236, 0, 0, 0.500171, -0.865927, 90, 100, 1, 'Pale Reach: hanging mold over Fresh Mold 9999003'),
(9993104, 2399012, 0, 0, 0, 1, 1, -7700.5, 1, 428.11, 3.927, 0, 0, 0.923956, -0.382499, 90, 100, 1, 'Pale Reach: hanging mold over Fresh Mold 9999004'),
(9993105, 2399012, 0, 0, 0, 1, 1, -7691.5, 4, 426.59, 2.356, 0, 0, 0.923842, 0.382773, 90, 100, 1, 'Pale Reach: hanging mold over Fresh Mold 9999005');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300683 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300683, 1, 0, 0, 70, 0, 100, 0, 3, 0, 0, 0, 0, 0, 41, 0, 90, 0, 0, 0, 0, 20, 2399012, 7, 0, 0, 0, 0, 0, 0, 'Fresh Mold - On collected - Take the hanging mold away for 90 s');
