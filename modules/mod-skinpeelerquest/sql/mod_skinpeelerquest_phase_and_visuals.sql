START TRANSACTION;

UPDATE `spellvisual_dbc`
SET `ChannelKit` = 0
WHERE `ID` = 99028;

DELETE FROM `creature_text` WHERE `CreatureID` = 9916212 AND `GroupID` = 0;
INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`,
 `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(9916212, 0, 0, 'The storm has come for you.', 14, 0, 100, 0, 0, 0, 0, 0, 'Stormfang encounter start');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 9916212 AND `id` = 1;
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
 `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`,
 `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`,
 `action_param2`, `action_param3`, `action_param4`, `action_param5`,
 `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
 `target_param4`, `comment`)
VALUES
(9916212, 0, 1, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 'Stormfang - encounter start yell');

COMMIT;
