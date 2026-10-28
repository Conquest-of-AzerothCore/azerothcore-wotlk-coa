-- Edwin VanCleef (639): Buster Call. At 66% and 33% health three markers call red circles on the floor and drop cannonballs on them
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `speed_walk`, `speed_run`, `unit_flags`, `unit_flags2`, `unit_class`, `type`, `AIName`, `ScriptName`, `HealthModifier`, `RegenHealth`, `flags_extra`) VALUES
(180238, 'Buster Call Marker', 21, 21, 14, 1, 1, 33554434, 2048, 1, 10, '', 'npc_ascension_buster_call_marker', 1, 0, 130) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`), `flags_extra` = VALUES(`flags_extra`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 180238;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(180238, 0, 11686, 1, 1, 0);

DELETE FROM `smart_scripts` WHERE `entryorguid` = 639 AND `source_type` = 0 AND `id` BETWEEN 9 AND 14;
UPDATE `smart_scripts` SET `link` = 9 WHERE `entryorguid` = 639 AND `source_type` = 0 AND `id` = 3;
UPDATE `smart_scripts` SET `link` = 12 WHERE `entryorguid` = 639 AND `source_type` = 0 AND `id` = 6;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(639, 0, 9, 10, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 180238, 3, 10000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Edwin VanCleef - Between 34-66% Health - Summon Buster Call Marker'),
(639, 0, 10, 11, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 180238, 3, 10000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Edwin VanCleef - Between 34-66% Health - Summon Buster Call Marker'),
(639, 0, 11, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 180238, 3, 10000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Edwin VanCleef - Between 34-66% Health - Summon Buster Call Marker'),
(639, 0, 12, 13, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 180238, 3, 10000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Edwin VanCleef - Between 0-33% Health - Summon Buster Call Marker'),
(639, 0, 13, 14, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 180238, 3, 10000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Edwin VanCleef - Between 0-33% Health - Summon Buster Call Marker'),
(639, 0, 14, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 180238, 3, 10000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Edwin VanCleef - Between 0-33% Health - Summon Buster Call Marker');
