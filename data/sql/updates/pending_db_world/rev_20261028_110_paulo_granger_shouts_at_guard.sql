-- Paulo Granger keeps shouting at Guard Thair Spada at the north gate: he faces the guard and throws up an arm
-- (exclamation animation) every few seconds, without chat text.
UPDATE `creature` SET `position_x` = -8349.84, `position_y` = 645.94, `position_z` = 95.5, `orientation` = 0.2381 WHERE `guid` = 9960151 AND `id` = 164986;
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164986;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 164986 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`,
    `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`,
    `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164986, 0, 0, 1, 1, 0, 100, 0, 1000, 3000, 3000, 5000, 0, 0, 66, 0, 0, 0, 0, 0, 0, 10, 9920212, 164980, 0, 0, 0, 0, 0, 0, 'Paulo Granger - Out of Combat - Face Guard Thair Spada'),
(164986, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 5, 5, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Paulo Granger - Linked - Play Emote Exclamation');
