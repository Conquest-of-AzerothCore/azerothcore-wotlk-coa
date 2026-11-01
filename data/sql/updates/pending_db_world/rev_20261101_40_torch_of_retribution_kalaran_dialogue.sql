-- The Torch of Retribution (quest 3453), #9913: SmartAI script 847900 (Kalaran Windblade 8479's incantation)
-- only ever played creature_text group 0, leaving groups 1-3 ("Be patient...", "falls to one knee...",
-- "It is done...") as dead data during the 60 s wait. Insert TALK actions for those groups across the same
-- window, so the player gets dialogue instead of a long silent animation before the quest completes.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 847900 AND `source_type` = 9;
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
 `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`,
 `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
 `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`,
 `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(847900, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Kalaran Windblade - On Script - Close Gossip'),
(847900, 9, 1, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kalaran Windblade - On Script - Remove Npc Flags Gossip & Questgiver'),
(847900, 9, 2, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kalaran Windblade - On Script - Talk Group 0 (chants in an unknown tongue)'),
(847900, 9, 3, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 17, 69, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kalaran Windblade - On Script - Set Emote State 69'),
(847900, 9, 4, 0, 0, 0, 100, 0, 20000, 20000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kalaran Windblade - On Script - Talk Group 1 (Be patient...)'),
(847900, 9, 5, 0, 0, 0, 100, 0, 25000, 25000, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kalaran Windblade - On Script - Talk Group 2 (falls to one knee)'),
(847900, 9, 6, 0, 0, 0, 100, 0, 15000, 15000, 0, 0, 0, 0, 17, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kalaran Windblade - On Script - Set Emote State 0'),
(847900, 9, 7, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kalaran Windblade - On Script - Talk Group 3 (It is done...)'),
(847900, 9, 8, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 15, 3453, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Kalaran Windblade - On Script - Quest Credit \'The Torch of Retribution\''),
(847900, 9, 9, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 82, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kalaran Windblade - On Script - Add Npc Flags Gossip & Questgiver');
