-- Naj'iri sits beside her dancing sister Raj'iri at The Crossroads and answers her after Play It by Ear and Dancing to the Beat
UPDATE `creature_template` SET `minlevel` = 8, `maxlevel` = 8, `faction` = 126 WHERE `entry` = 741719;
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 41719;

DELETE FROM `creature_template_addon` WHERE `entry` IN (41719,741719);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(41719, 0, 0, 0, 0, 10, 0, NULL),
(741719, 0, 0, 1, 0, 0, 0, NULL);

DELETE FROM `creature` WHERE `guid` = 9010705;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9010705, 741719, 1, 0, 0, 1, 1, 0, -392.035, -2606.498, 96.351, 2.32863, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Crossroads: Naj''iri sitting at the right hand of Raj''iri (9010700)');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 41719 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(41719, 0, 0, 0, 20, 0, 100, 0, 255078, 0, 0, 0, 0, 0, 80, 4171900, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Raj''iri - On Quest ''Play It by Ear'' Rewarded - Run Script'),
(41719, 0, 1, 0, 20, 0, 100, 0, 255080, 0, 0, 0, 0, 0, 80, 4171901, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Raj''iri - On Quest ''Dancing to the Beat'' Rewarded - Run Script');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (4171900,4171901) AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(4171900, 9, 0, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Raj''iri - Actionlist - Say Line 0'),
(4171900, 9, 1, 0, 0, 0, 100, 0, 4000, 4000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 19, 741719, 10, 0, 0, 0, 0, 0, 0, 'Raj''iri - Actionlist - Say Line 0 (Naj''iri)'),
(4171901, 9, 0, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Raj''iri - Actionlist - Say Line 1'),
(4171901, 9, 1, 0, 0, 0, 100, 0, 4000, 4000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 19, 741719, 10, 0, 0, 0, 0, 0, 0, 'Raj''iri - Actionlist - Say Line 1 (Naj''iri)'),
(4171901, 9, 2, 0, 0, 0, 100, 0, 2000, 2000, 0, 0, 0, 0, 91, 1, 0, 0, 0, 0, 0, 19, 741719, 10, 0, 0, 0, 0, 0, 0, 'Raj''iri - Actionlist - Remove Bytes 1 Sit (Naj''iri)'),
(4171901, 9, 3, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 17, 10, 0, 0, 0, 0, 0, 19, 741719, 10, 0, 0, 0, 0, 0, 0, 'Raj''iri - Actionlist - Set Emote State Dance (Naj''iri)'),
(4171901, 9, 4, 0, 0, 0, 100, 0, 30000, 30000, 0, 0, 0, 0, 17, 0, 0, 0, 0, 0, 0, 19, 741719, 10, 0, 0, 0, 0, 0, 0, 'Raj''iri - Actionlist - Set Emote State None (Naj''iri)'),
(4171901, 9, 5, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 90, 1, 0, 0, 0, 0, 0, 19, 741719, 10, 0, 0, 0, 0, 0, 0, 'Raj''iri - Actionlist - Set Bytes 1 Sit (Naj''iri)');
