--
-- #10437 follow-up: the Cage (2300662) is a non-consumable GOOBER that never despawns, so its AI never resets and
-- the not-repeatable On Use credit fired once per grid load for the whole server. The Cage now credits only
-- players on A Troll's Grim Mercy (175053), despawns once its hostage has left and respawns per its spawn timer.
-- The despawn lands inside the 45 s open window, before the GOOBER clears GO_FLAG_IN_USE, so the respawn clears it.
-- #10409 follow-up: Horde Supplies (2300709) despawns on the next update instead of staying clickable for 1 s.
--
DELETE FROM `smart_scripts` WHERE (`entryorguid`,`source_type`) IN ((2300662,1));
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300662, 1, 0, 1, 64, 0, 100, 1, 1, 0, 0, 0, 0, 0, 33, 164064, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Cage - On Use (not repeatable) - Quest Credit Hostages freed'),
(2300662, 1, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 19, 164064, 4, 0, 0, 0, 0, 0, 0, 'Cage - On Link - Set Data 1 1 on caged Captive Hostage'),
(2300662, 1, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 8000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Cage - On Link - Despawn after the hostage leaves, respawns per spawn timer'),
(2300662, 1, 3, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 106, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Cage - On Respawn - Remove In Use left by the despawn while open');

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = 2300662 AND `SourceId` = 1;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 2300662, 1, 0, 9, 0, 175053, 0, 0, 0, 0, 0, '', 'Cage - opens only for players on A Troll''s Grim Mercy');

UPDATE `smart_scripts`
SET `action_param1` = 0, `comment` = 'Horde Supplies - On Use - Destroyed at once, respawns per spawn timer'
WHERE `entryorguid` = 2300709 AND `source_type` = 1 AND `id` = 0 AND `action_type` = 41;
