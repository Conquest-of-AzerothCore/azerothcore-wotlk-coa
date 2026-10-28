-- High Inquisitor Whitemane: wake players and pets from Deep Sleep when she re-engages after the resurrection
DELETE FROM `smart_scripts` WHERE `entryorguid` = 397701 AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(397701, 9, 0, 0, 0, 0, 100, 0, 4500, 4500, 0, 0, 0, 0, 11, 9232, 0, 0, 0, 0, 0, 19, 3976, 50, 0, 0, 0, 0, 0, 0, 'High Inquisitor Whitemane - Actionlist - Cast \'Scarlet Resurrection\''),
(397701, 9, 1, 0, 0, 0, 100, 0, 1900, 1900, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'High Inquisitor Whitemane - Actionlist - Say Line 2'),
(397701, 9, 2, 0, 0, 0, 100, 0, 1400, 1400, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'High Inquisitor Whitemane - Actionlist - Set Sheath Unarmed'),
(397701, 9, 3, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 5, 66, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'High Inquisitor Whitemane - Actionlist - Play Emote 66'),
(397701, 9, 4, 0, 0, 0, 100, 0, 2000, 2000, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'High Inquisitor Whitemane - Actionlist - Reset Invincibility Hp'),
(397701, 9, 5, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 9256, 0, 0, 0, 0, 0, 18, 100, 0, 0, 0, 0, 0, 0, 0, 'High Inquisitor Whitemane - Actionlist - Remove Aura \'Deep Sleep\' from Players'),
(397701, 9, 6, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 9256, 0, 0, 0, 0, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 'High Inquisitor Whitemane - Actionlist - Remove Aura \'Deep Sleep\' from Creatures'),
(397701, 9, 7, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'High Inquisitor Whitemane - Actionlist - Set Reactstate Aggressive'),
(397701, 9, 8, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'High Inquisitor Whitemane - Actionlist - Set Event Phase 2'),
(397701, 9, 9, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'High Inquisitor Whitemane - Actionlist - Start Attacking'),
(397701, 9, 10, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 117, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'High Inquisitor Whitemane - Actionlist - Enable Evade');
