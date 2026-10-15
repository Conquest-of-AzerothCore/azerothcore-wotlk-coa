-- "Elven Magic": "Magical barrier crossed" comes from the two client trigger zones (6163, 6164) on the way from the Darengar
-- Estate into the Gilded Vale. The helper the step counts did not exist and is added.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_flags`, `flags_extra`) VALUES
(164508, '[KC] Magical barrier crossed', 1, 1, 35, 33554432, 128) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `flags_extra` = VALUES(`flags_extra`);
DELETE FROM `areatrigger_scripts` WHERE `entry` IN (6163, 6164);
INSERT INTO `areatrigger_scripts` (`entry`, `ScriptName`) VALUES
(6163, 'SmartTrigger'),
(6164, 'SmartTrigger');
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (6163, 6164) AND `source_type` = 2;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(6163, 2, 0, 0, 46, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164508, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gilded Vale barrier - On Trigger - Quest Credit ''Magical barrier crossed'''),
(6164, 2, 0, 0, 46, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164508, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gilded Vale barrier - On Trigger - Quest Credit ''Magical barrier crossed''');
