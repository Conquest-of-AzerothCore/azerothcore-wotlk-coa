-- Nests and Feathers (175065): the Daumor Gryphons (164080, 164188) roosting on the nests had no script, so they never
-- knocked anyone back and ignored the quest's Throw Meat (365038, item 559953), which also landed on any target.
-- On the realm a roosting gryphon buffets a player who walks up to its nest about a second later; a gryphon hit by
-- the meat stands, rises from the nest a second later and flies off, so the nest can be cleaned; it does not knock
-- back while leaving, and it returns 30 s after it is gone (user, live).
-- Evidence: video 9elvxh9Fct0 00:44:40-00:44:42 (wings spread, player pushed ~10 yd down the snow), 00:44:57-00:45:05
-- (2 s Throw Meat, take-off at 00:45:02, Cleaning at 00:45:03, 1/5) and 00:45:24-00:45:30; o6AaRPzuChg 00:18:42.
-- The realm's buffet spell is unknown (MobSpells lists only Sit 365372). The gryphons are friendly, so the
-- enemy-only Gryphon Wing Flap (21189) cannot hit a player, and stock Knockback (10689) draws a spell swirl on the
-- player. The gryphon stands, flaps (mount-special emote 377) and pushes with the visual-less 2145722, which has
-- Knockback's speeds (any unit, 10 yd/s out and up), and sits again 3 s after its last push. Cleaning is a 1 s cast
-- on the realm too (00:45:03.0-00:45:04.0), so the push comes 0.7 s after a player steps in and can repeat every
-- 2 s: a player who runs back in is pushed again before the cast ends. The take-off flight is scripted, so the
-- core must not reset its movement flags.
UPDATE `creature_template` SET `AIName` = 'SmartAI', `flags_extra` = `flags_extra` | 512 WHERE `entry` IN (164080, 164188);

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (164080, 164188) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164080, 0, 0, 1, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - On Reset - Set Event Phase 1 (roosting)'),
(164080, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Linked - Set Fly Off'),
(164080, 0, 2, 0, 10, 1, 100, 0, 2, 6, 2000, 2000, 1, 0, 80, 16408000, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Player Within 6 yd - Run Script (Knockback)'),
(164080, 0, 3, 0, 8, 1, 100, 0, 365038, 0, 0, 0, 0, 0, 80, 16408001, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - On Spellhit Throw Meat - Run Script (Fly Away)'),
(164080, 0, 4, 0, 34, 2, 100, 0, 8, 1, 0, 0, 0, 0, 69, 2, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -7130, 250, 540, 0, 'Daumor Gryphon - On Point 1 Reached - Fly South-East Over The Valley'),
(164080, 0, 5, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 70, 0, 0, 0, 0, 0, 0, 20, 2300669, 5, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - On Respawn - Respawn Its Nest'),
(164080, 0, 6, 7, 59, 1, 100, 0, 2, 0, 0, 0, 0, 0, 75, 365372, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - On Timed Event 2 (roosting) - Add Aura Sit'),
(164080, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 90, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Linked - Sit Down'),
(164188, 0, 0, 1, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - On Reset - Set Event Phase 1 (roosting)'),
(164188, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Linked - Set Fly Off'),
(164188, 0, 2, 0, 10, 1, 100, 0, 2, 6, 2000, 2000, 1, 0, 80, 16408000, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Player Within 6 yd - Run Script (Knockback)'),
(164188, 0, 3, 0, 8, 1, 100, 0, 365038, 0, 0, 0, 0, 0, 80, 16408001, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - On Spellhit Throw Meat - Run Script (Fly Away)'),
(164188, 0, 4, 0, 34, 2, 100, 0, 8, 1, 0, 0, 0, 0, 69, 2, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -7130, 250, 540, 0, 'Daumor Gryphon - On Point 1 Reached - Fly South-East Over The Valley'),
(164188, 0, 5, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 70, 0, 0, 0, 0, 0, 0, 20, 2300669, 5, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - On Respawn - Respawn Its Nest'),
(164188, 0, 6, 7, 59, 1, 100, 0, 2, 0, 0, 0, 0, 0, 75, 365372, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - On Timed Event 2 (roosting) - Add Aura Sit'),
(164188, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 90, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Linked - Sit Down');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (16408000, 16408001) AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(16408000, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 74, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Actionlist - Remove Timed Event 2'),
(16408000, 9, 1, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 365372, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Actionlist - Remove Aura Sit'),
(16408000, 9, 2, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 91, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Actionlist - Stand Up'),
(16408000, 9, 3, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 5, 377, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Actionlist - Flap Wings'),
(16408000, 9, 4, 0, 0, 0, 100, 0, 700, 700, 0, 0, 0, 0, 11, 2145722, 2, 0, 0, 0, 0, 17, 0, 6, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Actionlist - Cast Knockback On Players Within 6 yd'),
(16408000, 9, 5, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 2, 3000, 3000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Actionlist - Create Timed Event 2 (Sit Again In 3 s)'),
(16408001, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Actionlist - Set Event Phase 2 (leaving)'),
(16408001, 9, 1, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 365372, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Actionlist - Remove Aura Sit'),
(16408001, 9, 2, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 91, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Actionlist - Stand Up'),
(16408001, 9, 3, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 60, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Actionlist - Set Fly On'),
(16408001, 9, 4, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 69, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 25, 0, 'Daumor Gryphon - Actionlist - Rise 25 yd From The Nest'),
(16408001, 9, 5, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 8000, 30, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Daumor Gryphon - Actionlist - Despawn In 8 s (Respawn 30 s)');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 17 AND `SourceGroup` = 0 AND `SourceEntry` = 365038;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(17, 0, 365038, 0, 0, 31, 1, 3, 164080, 0, 0, 0, 0, '', 'Throw Meat only at a Daumor Gryphon'),
(17, 0, 365038, 0, 1, 31, 1, 3, 164188, 0, 0, 0, 0, '', 'Throw Meat only at a Daumor Gryphon');

-- A Nest can be reached from up to 11 yd (its model's box plus Opening's 5 yd), outside the gryphon's push. Within
-- Daumor Peak (10248), Opening (3365) on a Nest now needs the nest's gryphon gone: no Daumor Gryphon within 3 yd.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 17 AND `SourceGroup` = 0 AND `SourceEntry` = 3365 AND ((`ConditionTypeOrReference` = 23 AND `ConditionValue1` = 10248) OR (`ConditionTypeOrReference` = 31 AND `ConditionValue2` = 2300669) OR (`ConditionTypeOrReference` = 29 AND `ConditionValue1` IN (164080, 164188)));
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(17, 0, 3365, 0, 0, 23, 0, 10248, 0, 0, 1, 173, 0, '', 'Opening outside Daumor Peak is unrestricted'),
(17, 0, 3365, 0, 1, 31, 1, 5, 2300669, 0, 1, 173, 0, '', 'Opening in Daumor Peak on anything but a Nest is unrestricted'),
(17, 0, 3365, 0, 2, 29, 1, 164080, 3, 0, 1, 173, 0, '', 'Opening on a Nest needs its Daumor Gryphon gone'),
(17, 0, 3365, 0, 2, 29, 1, 164188, 3, 0, 1, 173, 0, '', 'Opening on a Nest needs its Daumor Gryphon gone');
