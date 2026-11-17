-- Celedorn's Bread (175105), #12397: the realm tracks one objective, "Distribute Celedorn's Enchanted Bread 0/4"
-- (i5vATMYui0I 35:12). The four 1-count objectives from #10294 printed "Sylana slain" for the blank lines. Each
-- inhabitant now credits Aldaria's counter for the feeding player alone and keeps a hidden passive mark, so each
-- takes only one loaf; the window closes so the option cannot be chosen twice.
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 164318, `RequiredNpcOrGoCount1` = 4, `RequiredNpcOrGo2` = 0,
    `RequiredNpcOrGoCount2` = 0, `RequiredNpcOrGo3` = 0, `RequiredNpcOrGoCount3` = 0, `RequiredNpcOrGo4` = 0,
    `RequiredNpcOrGoCount4` = 0 WHERE `ID` = 175105;

UPDATE `quest_poi` SET `ObjectiveIndex` = 0 WHERE `QuestID` = 175105 AND `id` IN (0, 1, 2, 3);

DELETE FROM `spell_dbc` WHERE `ID` IN (9978010, 9978011, 9978012, 9978013);
INSERT INTO `spell_dbc` (`ID`, `Attributes`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`, `EquippedItemClass`,
    `Effect_1`, `ImplicitTargetA_1`, `EffectAura_1`, `SchoolMask`, `Name_Lang_enUS`, `Name_Lang_Mask`) VALUES
(9978010, 448, 1, 21, 1, -1, 6, 1, 4, 1, 'Celedorn''s Bread: Aldaria', 16712190),
(9978011, 448, 1, 21, 1, -1, 6, 1, 4, 1, 'Celedorn''s Bread: Sylana', 16712190),
(9978012, 448, 1, 21, 1, -1, 6, 1, 4, 1, 'Celedorn''s Bread: Findan', 16712190),
(9978013, 448, 1, 21, 1, -1, 6, 1, 4, 1, 'Celedorn''s Bread: Remmos', 16712190);
DELETE FROM `spell_dbc` WHERE `ID` = 9978014;
INSERT INTO `spell_dbc` (`ID`, `Attributes`, `CastingTimeIndex`, `RangeIndex`, `EquippedItemClass`, `Effect_1`,
    `ImplicitTargetA_1`, `EffectMiscValue_1`, `SchoolMask`, `Name_Lang_enUS`, `Name_Lang_Mask`) VALUES
(9978014, 384, 1, 1, -1, 90, 1, 164318, 1, 'Celedorn''s Bread: Credit', 16712190);

-- Passive auras are not sent to the client; force saving keeps the marks through a relog.
DELETE FROM `spell_custom_attr` WHERE `spell_id` IN (9978010, 9978011, 9978012, 9978013);
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES
(9978010, 0x20000800),
(9978011, 0x20000800),
(9978012, 0x20000800),
(9978013, 0x20000800);

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (164318, 164319, 164320, 164321) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164318, 0, 0, 1, 62, 0, 100, 0, 1200398, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Aldaria - On Gossip Option 0 Selected - Close Gossip'),
(164318, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 75, 9978010, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Aldaria - Linked - Mark Aldaria fed'),
(164318, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 134, 9978014, 2, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Aldaria - Linked - Invoker Cast Quest Credit Distribute Celedorn''s Enchanted Bread'),
(164319, 0, 0, 1, 62, 0, 100, 0, 1200399, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Sylana - On Gossip Option 0 Selected - Close Gossip'),
(164319, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 75, 9978011, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Sylana - Linked - Mark Sylana fed'),
(164319, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 134, 9978014, 2, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Sylana - Linked - Invoker Cast Quest Credit Distribute Celedorn''s Enchanted Bread'),
(164320, 0, 0, 1, 62, 0, 100, 0, 1200400, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Findan - On Gossip Option 0 Selected - Close Gossip'),
(164320, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 75, 9978012, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Findan - Linked - Mark Findan fed'),
(164320, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 134, 9978014, 2, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Findan - Linked - Invoker Cast Quest Credit Distribute Celedorn''s Enchanted Bread'),
(164321, 0, 0, 1, 62, 0, 100, 0, 1200401, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Remmos - On Gossip Option 0 Selected - Close Gossip'),
(164321, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 75, 9978013, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Remmos - Linked - Mark Remmos fed'),
(164321, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 134, 9978014, 2, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Remmos - Linked - Invoker Cast Quest Credit Distribute Celedorn''s Enchanted Bread');

-- Magister Celedorn clears the marks when the quest is taken again or turned in.
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164315;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164315 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164315, 0, 0, 1, 19, 0, 100, 0, 175105, 0, 0, 0, 0, 0, 28, 9978010, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Magister Celedorn - On Celedorn''s Bread Accepted - Remove Aldaria mark'),
(164315, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 9978011, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Magister Celedorn - Linked - Remove Sylana mark'),
(164315, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 9978012, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Magister Celedorn - Linked - Remove Findan mark'),
(164315, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 9978013, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Magister Celedorn - Linked - Remove Remmos mark'),
(164315, 0, 4, 5, 20, 0, 100, 0, 175105, 0, 0, 0, 0, 0, 28, 9978010, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Magister Celedorn - On Celedorn''s Bread Rewarded - Remove Aldaria mark'),
(164315, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 9978011, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Magister Celedorn - Linked - Remove Sylana mark'),
(164315, 0, 6, 7, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 9978012, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Magister Celedorn - Linked - Remove Findan mark'),
(164315, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 9978013, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Magister Celedorn - Linked - Remove Remmos mark');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` IN (1200398, 1200399, 1200400, 1200401)
    AND `SourceEntry` = 0 AND `ConditionTypeOrReference` IN (1, 48);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
    `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
    `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 1200398, 0, 0, 0, 1, 0, 9978010, 0, 0, 1, 0, 0, '', 'Aldaria bread option: not yet fed'),
(15, 1200399, 0, 0, 0, 1, 0, 9978011, 0, 0, 1, 0, 0, '', 'Sylana bread option: not yet fed'),
(15, 1200400, 0, 0, 0, 1, 0, 9978012, 0, 0, 1, 0, 0, '', 'Findan bread option: not yet fed'),
(15, 1200401, 0, 0, 0, 1, 0, 9978013, 0, 0, 1, 0, 0, '', 'Remmos bread option: not yet fed');
