-- Stay a While (1660060), Goldshire: ending the lesson early left Aliscar's lesson action list running.
-- The projection's "Thank you, I've heard enough." gossip (162943, id 3) starts the 16280601 list on
-- Aliscar, but SmartScript::SetScript9 refuses to replace a running timed action list unless
-- allowOverride is set, and it returns without starting anything. For SMART_ACTION_CALL_TIMED_ACTIONLIST
-- the parameters are action_param1 = list id, action_param2 = timer type and action_param3 = allowOverride
-- (SmartAction::timedActionList in SmartScriptMgr.h), so the call was dropped: the early-ending option was
-- never withdrawn and the 16280600 lesson kept running. Its later step 8 then teleported the player from
-- wherever they were back to Aliscar's stall, which is the late teleport reported after the quest had
-- already been handed in. Setting the flag makes 16280601 replace the lesson list, so no step of the
-- lesson can fire after the player leaves early.
UPDATE `smart_scripts` SET `action_param3` = 1
WHERE `entryorguid` = 162943 AND `source_type` = 0 AND `id` = 3;
