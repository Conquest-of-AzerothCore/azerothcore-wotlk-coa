-- Cookie (645): when he gets aggro he jumps into his cauldron and stays there, throwing food, throwing poison vials and cooking, with no Acid Splash; the cauldron is spawned as a Boiling Cauldron of size 1
DELETE FROM `smart_scripts` WHERE `entryorguid` = 645 AND `source_type` = 0 AND `id` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 645 AND `source_type` = 0 AND `id` BETWEEN 2 AND 10;
UPDATE `smart_scripts` SET `event_phase_mask` = 2, `event_param1` = 20000, `event_param2` = 25000, `event_param3` = 30000, `event_param4` = 40000, `action_param1` = 2102590, `action_param2` = 1 WHERE `entryorguid` = 645 AND `source_type` = 0 AND `id` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(645, 0, 2, 3, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Cookie - On Aggro - Stop Combat Movement'),
(645, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 97, 30, 8, 0, 0, 0, 0, 1, 0, 0, 0, 0, -69.131, -852.869, 17.634597, 4.654749, 'Cookie - On Aggro - Jump Into Cauldron'),
(645, 0, 4, 5, 34, 0, 100, 0, 16, 0, 0, 0, 0, 0, 22, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Cookie - Landed In Cauldron - Set Phase 2'),
(645, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 103, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Cookie - Landed In Cauldron - Root'),
(645, 0, 6, 7, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Cookie - On Evade - Set Phase 0'),
(645, 0, 7, 8, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Cookie - On Evade - Allow Combat Movement'),
(645, 0, 8, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 103, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Cookie - On Evade - Unroot'),
(645, 0, 9, 0, 0, 2, 100, 0, 1500, 2500, 1600, 1700, 0, 0, 11, 2102589, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Cookie - In Cauldron - Cast Throw Food'),
(645, 0, 10, 0, 0, 2, 100, 0, 8000, 12000, 12000, 18000, 0, 0, 11, 2102527, 1, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 'Cookie - In Cauldron - Cast Throw Poison Vial');

DELETE FROM `gameobject` WHERE `guid` = 8001308;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(8001308, 18342, 36, 1581, 1581, 1, 1, -69.016045, -852.7928, 17.034597, 4.654749, 0, 0, 0.727189, -0.686437, 300, 100, 1, 'Cookie\'s cauldron');
