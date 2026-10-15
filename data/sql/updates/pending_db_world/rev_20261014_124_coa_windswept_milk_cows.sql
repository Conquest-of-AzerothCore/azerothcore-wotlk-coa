-- "Windswept Milk": a player on the quest clicks a Dairy Cow at Windswept Summit to fill a Windswept Milk Bucket (8
-- needed), as on live (user). Each cow can be milked again a minute later; without the quest a click does nothing.
UPDATE `creature_template` SET `npcflag` = `npcflag` | 1, `AIName` = 'SmartAI' WHERE `entry` = 164158;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164158 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164158, 0, 0, 1, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 56, 559893, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dairy Cow - On Gossip Hello - Add Item ''Windswept Milk Bucket'''),
(164158, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dairy Cow - Linked - Close Gossip'),
(164158, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dairy Cow - Linked - Remove Npc Flag Gossip'),
(164158, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dairy Cow - Linked - Create Timed Event 1 (60 s)'),
(164158, 0, 4, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dairy Cow - On Timed Event 1 - Add Npc Flag Gossip');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = 164158;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 164158, 0, 0, 9, 0, 175074, 0, 0, 0, 0, 0, '', 'Dairy Cow gives milk only to players on Windswept Milk');
