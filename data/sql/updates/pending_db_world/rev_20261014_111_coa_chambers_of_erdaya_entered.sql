-- "The Chambers of Erdaya": the "Chambers of Erdaya entered" step counts an invisible helper that did not exist. It is
-- added, and a player who reaches Enilith Naemyl inside the Chambers gets the credit.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_flags`, `flags_extra`) VALUES
(164524, '[KC] Chambers of Erdaya entered', 1, 1, 35, 33554432, 128) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `flags_extra` = VALUES(`flags_extra`);
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164309;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164309 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164309, 0, 0, 0, 10, 0, 100, 0, 2, 40, 3000, 3000, 1, 0, 33, 164524, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Enilith Naemyl - Player Within 40 Yards - Quest Credit ''Chambers of Erdaya entered''');
