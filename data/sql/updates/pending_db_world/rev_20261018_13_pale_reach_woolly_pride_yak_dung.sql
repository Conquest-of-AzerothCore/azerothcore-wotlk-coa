-- Woolly Pride (175133), issue #7994: the Yak Dung in the Nivelarn stables used model 131060 (a later-expansion spell
-- effect missing from the 3.3.5 client, so the piles were invisible) and answered clicks with an empty "Greetings" window.
-- The piles now use the Duskwood haystack (dirty straw, as the quest text says), clicking a pile or a yak closes the window,
-- and only players on the quest clean a pile (credit, then it vanishes and returns after 60 s).
DELETE FROM `creature_template_model` WHERE `CreatureID` = 165503;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(165503, 0, 26764, 0.4, 1, 0);
DELETE FROM `smart_scripts` WHERE `entryorguid` = 165503 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(165503, 0, 0, 1, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 165503, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Yak Dung - On Gossip Hello - Quest Credit Stables cleaned (175133)'),
(165503, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 1000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Yak Dung - Linked - Despawn (respawn 60 s)'),
(165503, 0, 2, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Yak Dung - On Gossip Hello - Close Gossip');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164420 AND `source_type` = 0 AND `id` = 4;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164420, 0, 4, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ealdfrost Yak - On Gossip Hello - Close Gossip');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = 165503 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 165503, 0, 0, 9, 0, 175133, 0, 0, 0, 0, 0, '', 'Yak Dung - only players on Woolly Pride clean a pile');
