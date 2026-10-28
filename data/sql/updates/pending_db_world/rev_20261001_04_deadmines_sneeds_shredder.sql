-- Sneed\'s Shredder (642): swap the vanilla Terrify/Distracting Pain for the Ascension saw blade spells; the saw blades are scripted in C++
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `speed_walk`, `speed_run`, `unit_flags`, `unit_flags2`, `unit_class`, `type`, `AIName`, `ScriptName`, `HealthModifier`, `RegenHealth`, `flags_extra`) VALUES
(180237, 'Buzzing Saw Blade', 20, 20, 17, 1.2, 0.5, 33554434, 2048, 1, 10, '', 'npc_ascension_buzzing_saw_blade', 1, 0, 8256) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `unit_flags` = VALUES(`unit_flags`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`), `flags_extra` = VALUES(`flags_extra`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 180237;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(180237, 0, 29164, 1, 1, 0);

DELETE FROM `smart_scripts` WHERE `entryorguid` = 180237 AND `source_type` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 18023700 AND `source_type` = 9;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 642 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(642, 0, 0, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 5141, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Sneed\'s Shredder - On Just Died - Cast Eject Sneed'),
(642, 0, 1, 0, 0, 0, 100, 0, 8400, 8400, 7800, 7800, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Sneed\'s Shredder - In Combat - Cast Fierce Blow'),
(642, 0, 2, 0, 0, 0, 100, 0, 12000, 15000, 20000, 25000, 0, 0, 11, 2102559, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Sneed\'s Shredder - In Combat - Cast Bouncing Saw Blade'),
(642, 0, 3, 0, 0, 0, 100, 0, 5000, 8000, 15000, 20000, 0, 0, 11, 2102569, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 'Sneed\'s Shredder - In Combat - Cast Throw Buzzing Saw Blade');
