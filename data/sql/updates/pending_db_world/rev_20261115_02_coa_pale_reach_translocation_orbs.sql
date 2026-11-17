-- Orbs of Translocation are buttons; with no auto-close time the first use left them in use until a restart, so
-- nobody else could click them. They now reset after 3 s.
UPDATE `gameobject_template` SET `data2` = 3000 WHERE `entry` IN (2310418, 2310419, 2310420, 2310421);

-- Namarien Sanctuary had two orbs at the foot of Lady Amaranthe's stairs (VGzezmaiv8A 20:24-20:30, V10AMkhYl6c
-- 9:12): the left one goes up to the Tilted Cliffs gazebo, the right one to Stormwind's Park (RIEMlZSgbQw
-- 1:49:36-1:49:56), whose orb in the high-elf gazebo leads back (VGzezmaiv8A 21:04-21:14). Each Namarien orb
-- stands on the centre of its floor rosette (placed in game by the user).
DELETE FROM `gameobject` WHERE `guid` IN (9995010, 9995011, 9995012);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9995010, 2310419, 0, 0, 0, 1, 1, -7551.868, 107.819, 268.635, 4.9, 0, 0, 0.637765, -0.770231, 300, 0, 1, 'Orb of Translocation, Namarien Sanctuary, left of the hall entrance below Lady Amaranthe'),
(9995011, 2310420, 0, 0, 0, 1, 1, -7547.772, 140.907, 268.636, 1.15, 0, 0, 0.543833, 0.839194, 300, 0, 1, 'Orb of Translocation, Namarien Sanctuary, right of the hall entrance below Lady Amaranthe'),
(9995012, 2310421, 0, 0, 0, 1, 1, -8681.78, 1103.44, 96.073, 1.5708, 0, 0, 0.707107, 0.707107, 300, 0, 1, 'Orb of Translocation, Stormwind City, The Park, in the high-elf gazebo');

DELETE FROM `gameobject_template_addon` WHERE `entry` = 2310420;
UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI' WHERE `entry` IN (2310419, 2310420, 2310421);
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (2310419, 2310420, 2310421) AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2310419, 1, 0, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 134, 365381, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Orb of Translocation (Namarien, to Tilted Cliffs) - On Gossip Hello - Invoker Cast Translocate'),
(2310420, 1, 0, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 134, 365382, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Orb of Translocation (Namarien, to Stormwind) - On Gossip Hello - Invoker Cast Translocate'),
(2310421, 1, 0, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 134, 365383, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Orb of Translocation (Stormwind Park, to Namarien) - On Gossip Hello - Invoker Cast Translocate');

-- The gazebo and Park orbs land players at the head of Amaranthe's stairs, facing down (RIEMlZSgbQw 1:49:43,
-- VGzezmaiv8A 21:14); the Namarien orbs land them beside the gazebo orb and south of the Park orb.
DELETE FROM `spell_target_position` WHERE `ID` IN (365380, 365381, 365382, 365383) AND `EffectIndex` = 0;
INSERT INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES
(365380, 0, 0, -7533.5, 123.0, 272.218, 3.1416, 0),
(365381, 0, 0, -7466.42, -82.71, 296.853, 0.562, 0),
(365382, 0, 0, -8684.8, 1103.4, 96.073, 0, 0),
(365383, 0, 0, -7533.5, 123.0, 272.218, 3.1416, 0);
