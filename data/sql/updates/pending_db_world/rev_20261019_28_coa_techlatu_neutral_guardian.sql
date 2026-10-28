-- CoA: 1660041 'A Door Left Ajar' - Techla'Tu, The Gatekeeper (161833) was hostile
-- (faction 14) instead of neutral as on live. Neutral (faction 7) creatures cannot be
-- attacked first, so the guardian also gains a proximity attack: anyone closing to
-- 10 yards is attacked, which keeps the required kill completable.
UPDATE `creature_template` SET `faction` = 7, `AIName` = 'SmartAI' WHERE `entry` = 161833;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 161833 AND `source_type` = 0 AND `id` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(161833, 0, 0, 0, 9, 0, 100, 0, 0, 10, 1000, 2000, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'TechlaTu, The Gatekeeper - Attack nearby players so the neutral guardian still fights');
