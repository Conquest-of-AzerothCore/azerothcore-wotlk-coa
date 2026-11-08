-- Soothing the Inner Gnoll (175026): a Hexed Bloodpaw Gnoll hit by Beldred's Potion (Throw Potion 365011) vanishes in a
-- polymorph puff and leaves a freed Miner (two in three) or a frog or a rabbit (one in six each). Each lasts 5 seconds; the
-- Miner thanks the thrower first. The existing quest credit on the same hit is unchanged.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164029 AND `source_type` = 0 AND `id` IN (1, 2, 3);
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (16402900, 16402901, 16402902) AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164029, 0, 1, 0, 8, 0, 100, 0, 365011, 0, 3000, 3000, 0, 0, 87, 16402900, 16402900, 16402900, 16402900, 16402901, 16402902, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hexed Bloodpaw Gnoll - On Spellhit Throw Potion - Call Random Transformation'),
(164029, 0, 2, 0, 17, 0, 100, 0, 0, 0, 0, 0, 0, 0, 134, 27123, 2, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Hexed Bloodpaw Gnoll - On Summoned Unit - Summon Casts Polymorph Impact Visual'),
(164029, 0, 3, 0, 17, 0, 100, 0, 164028, 0, 0, 0, 0, 0, 100, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Hexed Bloodpaw Gnoll - On Summoned Miner - Send Potion Thrower To Miner'),
(16402900, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Hexed Bloodpaw Gnoll - Actionlist - Store Potion Thrower'),
(16402900, 9, 1, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 164028, 3, 5000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hexed Bloodpaw Gnoll - Actionlist - Summon Miner for 5 seconds'),
(16402900, 9, 2, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hexed Bloodpaw Gnoll - Actionlist - Despawn'),
(16402901, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 13321, 3, 5000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hexed Bloodpaw Gnoll - Actionlist - Summon Frog for 5 seconds'),
(16402901, 9, 1, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hexed Bloodpaw Gnoll - Actionlist - Despawn'),
(16402902, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 721, 3, 5000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hexed Bloodpaw Gnoll - Actionlist - Summon Rabbit for 5 seconds'),
(16402902, 9, 1, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hexed Bloodpaw Gnoll - Actionlist - Despawn');

-- Beldred's Potion can only be thrown at a Hexed Bloodpaw Gnoll at or below half health, and only then transforms it, so
-- every throw that lands also earns the quest credit (gated the same way).
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 17 AND `SourceEntry` = 365011;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 2 AND `SourceEntry` = 164029 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(17, 0, 365011, 0, 0, 31, 1, 3, 164029, 0, 0, 0, 0, '', 'Throw Potion - target must be a Hexed Bloodpaw Gnoll'),
(17, 0, 365011, 0, 0, 38, 1, 50, 4, 0, 0, 0, 0, '', 'Throw Potion - target must be at or below 50% health'),
(22, 2, 164029, 0, 0, 38, 1, 50, 4, 0, 0, 0, 0, '', 'Hexed Bloodpaw Gnoll - Throw Potion transforms only a weakened gnoll');

-- The freed Miner turns to the thrower and says one of two lines half a second after appearing. Placed Miners are not
-- summoned, so they never run these events.
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164028;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164028 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164028, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 500, 500, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Miner - Just Summoned - Create Timed Event'),
(164028, 0, 1, 2, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Miner - On Timed Event - Face Potion Thrower'),
(164028, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Miner - Linked - Say Line 0 to Potion Thrower');

DELETE FROM `creature_text` WHERE `CreatureID` = 164028;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(164028, 0, 0, 'At last this nightmare is over!', 12, 0, 50, 0, 0, 0, 0, 0, 'Miner - freed by Beldred''s Potion'),
(164028, 0, 1, 'I''m free! Thank you $n', 12, 0, 50, 0, 0, 0, 0, 0, 'Miner - freed by Beldred''s Potion');
