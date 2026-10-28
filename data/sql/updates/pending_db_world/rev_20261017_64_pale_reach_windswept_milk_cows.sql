-- Windswept Milk (175074): the Dairy Cows could not be clicked, so nothing ever cast Milking on them. As on live (user):
-- clicking a Dairy Cow casts Milking (2 s) and the finished cast gives one Windswept Milk Bucket; a milked cow can be
-- milked again after three minutes, and only players on the quest can milk.
UPDATE `creature_template` SET `npcflag` = (`npcflag` & ~1) | 16777216, `AIName` = 'SmartAI' WHERE `entry` = 164158;
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 164158;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`) VALUES
(164158, 365040, 1, 0);
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164158 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164158, 0, 0, 1, 8, 0, 100, 0, 365040, 0, 0, 0, 0, 0, 56, 559893, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dairy Cow - On Spellhit ''Milking'' - Add Item ''Windswept Milk Bucket'''),
(164158, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 16777216, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dairy Cow - Linked - Remove Npc Flag Spellclick'),
(164158, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 180000, 180000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dairy Cow - Linked - Create Timed Event 1 (3 min)'),
(164158, 0, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 16777216, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dairy Cow - On Timed Event 1 - Add Npc Flag Spellclick');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = 164158;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 18 AND `SourceGroup` = 164158 AND `SourceEntry` = 365040;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(18, 164158, 365040, 0, 0, 9, 0, 175074, 0, 0, 0, 0, 0, '', 'Dairy Cow can be milked only by players on Windswept Milk');
