--
-- #10437: Pale Reach "Cage" GO (2300662) On Use fires on every click (spam quest credit and
-- Captive Hostage banter, even after the quest objective is complete). Set
-- SMART_EVENT_FLAG_NOT_REPEATABLE (1) on the On Use event so each spawned Cage grants credit once.
--
DELETE FROM `smart_scripts` WHERE (`entryorguid`,`source_type`) IN ((2300662,1));
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300662, 1, 0, 1, 64, 0, 100, 1, 1, 0, 0, 0, 0, 0, 33, 164064, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Cage - On Use (not repeatable) - Quest Credit Hostages freed'),
(2300662, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 19, 164064, 4, 0, 0, 0, 0, 0, 0, 'Cage - On Link - Set Data 1 1 on caged Captive Hostage');
