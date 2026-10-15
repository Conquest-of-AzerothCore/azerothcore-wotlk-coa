-- Noxxion: finish summoning his spawns before he turns unselectable and stunned
DELETE FROM `smart_scripts` WHERE `entryorguid` = 13282 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(13282, 0, 0, 0, 0, 0, 100, 0, 4000, 8000, 13000, 13000, 0, 0, 11, 21687, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Noxxion - In Combat - Cast Toxic Volley'),
(13282, 0, 1, 0, 0, 0, 100, 0, 9000, 14000, 13000, 13000, 0, 0, 11, 10966, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Noxxion - In Combat - Cast Uppercut'),
(13282, 0, 2, 0, 2, 0, 100, 1, 0, 50, 0, 0, 0, 0, 11, 21707, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Noxxion - Health Between 0-50% - Cast Summon Noxxion\'s Spawns'),
(13282, 0, 3, 4, 17, 0, 100, 1, 13456, 0, 0, 0, 0, 0, 11, 21708, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Noxxion - On Noxxion\'s Spawn Summoned - Cast Summon Noxxion\'s Spawns'),
(13282, 0, 4, 5, 61, 0, 100, 512, 0, 0, 0, 0, 0, 0, 63, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Noxxion - On Noxxion\'s Spawn Summoned - Reset Counter'),
(13282, 0, 5, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 0, 18, 33554432, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Noxxion - On Noxxion\'s Spawn Summoned - Set Unit Flag'),
(13282, 0, 6, 0, 35, 0, 100, 512, 0, 0, 0, 0, 0, 0, 63, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Noxxion - Summoned Creature Despawn - Set Counter'),
(13282, 0, 7, 11, 77, 0, 100, 512, 1, 5, 0, 0, 0, 0, 28, 21708, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Noxxion - On Counter Set - Remove Aura'),
(13282, 0, 8, 9, 6, 0, 100, 512, 0, 0, 0, 0, 0, 0, 118, 0, 0, 0, 0, 0, 0, 14, 32906, 178570, 0, 0, 0, 0, 0, 0, 'Noxxion - On Just Died - Set GO State'),
(13282, 0, 9, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 0, 34, 0, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Noxxion - On Just Died - Set Instance Data 0 to 3'),
(13282, 0, 10, 11, 25, 0, 100, 512, 0, 0, 0, 0, 0, 0, 41, 500, 0, 0, 0, 0, 0, 11, 13456, 100, 0, 0, 0, 0, 0, 0, 'Noxxion - On Reset - Despawn Minions'),
(13282, 0, 11, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 0, 19, 33554432, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Noxxion - On Reset - Remove Unit Flag');
