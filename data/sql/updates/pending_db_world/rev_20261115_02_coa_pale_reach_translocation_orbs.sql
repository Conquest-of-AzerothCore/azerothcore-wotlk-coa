-- Orbs of Translocation are buttons; with no auto-close time the first use left them in use until a restart, so
-- nobody else could click them. They now reset after 3 s.
UPDATE `gameobject_template` SET `data2` = 3000 WHERE `entry` IN (2310418, 2310419, 2310420, 2310421);

-- Namarien Sanctuary had two orbs at the foot of Lady Amaranthe's stairs (VGzezmaiv8A 20:24-20:30, V10AMkhYl6c
-- 9:12). The left one goes up to the Tilted Cliffs gazebo; nothing shows where the right one led, so it stays
-- unselectable until that is known.
DELETE FROM `gameobject` WHERE `guid` IN (9995010, 9995011);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9995010, 2310419, 0, 0, 0, 1, 1, -7547.78, 110.13, 268.642, 4.9, 0, 0, 0.637765, -0.770231, 300, 0, 1, 'Orb of Translocation, Namarien Sanctuary, left of the hall entrance below Lady Amaranthe'),
(9995011, 2310420, 0, 0, 0, 1, 1, -7544.65, 137.22, 268.641, 1.15, 0, 0, 0.543833, 0.839194, 300, 0, 1, 'Orb of Translocation, Namarien Sanctuary, right of the hall entrance below Lady Amaranthe');

DELETE FROM `gameobject_template_addon` WHERE `entry` = 2310420;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`, `artkit2`, `artkit3`) VALUES
(2310420, 0, 16, 0, 0, 0, 0, 0, 0);

UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI' WHERE `entry` = 2310419;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 2310419 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2310419, 1, 0, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 134, 365381, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Orb of Translocation (Namarien Sanctuary) - On Gossip Hello - Invoker Cast Translocate');

-- The gazebo orb landed players on Lady Amaranthe herself; both orbs now land beside the other end.
DELETE FROM `spell_target_position` WHERE `ID` IN (365380, 365381) AND `EffectIndex` = 0;
INSERT INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES
(365380, 0, 0, -7544.3, 111.2, 268.643, 0.41, 0),
(365381, 0, 0, -7466.42, -82.71, 296.853, 0.562, 0);
