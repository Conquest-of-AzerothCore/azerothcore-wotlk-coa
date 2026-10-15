-- Quest steps that are a place to reach, hooked to the client trigger zone standing on the people or place the quest names:
-- zone 6168 holds Arathel ("Arathel's camp reached"), 6171 the six Rockrend Survivors ("Survivors located"), 6172 the
-- Baile Escada Ealdir ("Baile Escada found") and 6177 the Ealdmaine Ealdir ("Ealdmaine Caverns discovered"). No zone is
-- near the missing miners of Ironbough Mine, so reaching a Miner counts as finding them. The helpers these steps count
-- did not exist and are added.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_flags`, `flags_extra`) VALUES
(164521, '[KC] Arathel''s camp reached', 1, 1, 35, 33554432, 128),
(164525, '[KC] Survivors located', 1, 1, 35, 33554432, 128),
(164530, '[KC] Baile Escada found', 1, 1, 35, 33554432, 128),
(164513, '[KC] Ealdmaine Caverns discovered', 1, 1, 35, 33554432, 128),
(164506, '[KC] Miners Found', 1, 1, 35, 33554432, 128) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `flags_extra` = VALUES(`flags_extra`);
DELETE FROM `areatrigger_scripts` WHERE `entry` IN (6168, 6171, 6172, 6177);
INSERT INTO `areatrigger_scripts` (`entry`, `ScriptName`) VALUES
(6168, 'SmartTrigger'),
(6171, 'SmartTrigger'),
(6172, 'SmartTrigger'),
(6177, 'SmartTrigger');
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (6168, 6171, 6172, 6177) AND `source_type` = 2;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(6168, 2, 0, 0, 46, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164521, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Arathel''s camp - On Trigger - Quest Credit ''Arathel''s camp reached'''),
(6171, 2, 0, 0, 46, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164525, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend survivors in the mine - On Trigger - Quest Credit ''Survivors located'''),
(6172, 2, 0, 0, 46, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164530, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Baile Escada - On Trigger - Quest Credit ''Baile Escada found'''),
(6177, 2, 0, 0, 46, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164513, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ealdmaine Caverns - On Trigger - Quest Credit ''Ealdmaine Caverns discovered''');
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164028;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164028 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164028, 0, 0, 0, 10, 0, 100, 0, 2, 10, 3000, 3000, 1, 0, 33, 164506, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Miner - Player Within 10 Yards - Quest Credit ''Miners Found''');
