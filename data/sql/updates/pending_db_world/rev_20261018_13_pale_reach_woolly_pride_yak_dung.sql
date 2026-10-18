-- Woolly Pride (175133), issue #7994: the Yak Dung in the Nivelarn stables was an NPC using model 131060 (a later-expansion
-- spell effect missing from the 3.3.5 client, so the piles were invisible) that answered clicks with an empty "Greetings"
-- window. The ten piles become clickable dung objects (the stock dung model 3675, Poodad01) on the same spots: a player on
-- the quest clicks one for "Stables cleaned" (credit 165503), and it vanishes and returns after 60 seconds. Clicking a yak
-- no longer opens a window either.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2300811, 10, 3675, 'Yak Dung', '', '', '', 1, 0, 175133, 0, 0, 'SmartGameObjectAI', '', 0) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `AIName` = VALUES(`AIName`);
DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300811 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300811, 1, 0, 1, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 165503, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Yak Dung - On Use - Quest Credit Stables cleaned (175133)'),
(2300811, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Yak Dung - Linked - Despawn (returns after the spawn time)');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = 2300811 AND `SourceId` = 1;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 2300811, 1, 0, 9, 0, 175133, 0, 0, 0, 0, 0, '', 'Yak Dung - only players on Woolly Pride clean a pile');
DELETE FROM `creature` WHERE `id` = 165503 AND `guid` BETWEEN 9985011 AND 9985020;
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9963600 AND 9963609;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9963600, 2300811, 0, 0, 0, 1, 1, -6401.7, 123.78, 513.94, 1.62, 0, 0, 0, 1, 60, 0, 1, '', 0, 'Woolly Pride: yak dung'),
(9963601, 2300811, 0, 0, 0, 1, 1, -6396.5, 131.5, 513.94, 3.4, 0, 0, 0, 1, 60, 0, 1, '', 0, 'Woolly Pride: yak dung'),
(9963602, 2300811, 0, 0, 0, 1, 1, -6408, 135, 513.57, 5.59, 0, 0, 0, 1, 60, 0, 1, '', 0, 'Woolly Pride: yak dung'),
(9963603, 2300811, 0, 0, 0, 1, 1, -6410, 131, 513.98, 6.16, 0, 0, 0, 1, 60, 0, 1, '', 0, 'Woolly Pride: yak dung'),
(9963604, 2300811, 0, 0, 0, 1, 1, -6425.5, 171, 507.54, 3.14, 0, 0, 0, 1, 60, 0, 1, '', 0, 'Woolly Pride: yak dung'),
(9963605, 2300811, 0, 0, 0, 1, 1, -6433, 170.5, 507.54, 0.17, 0, 0, 0, 1, 60, 0, 1, '', 0, 'Woolly Pride: yak dung'),
(9963606, 2300811, 0, 0, 0, 1, 1, -6426, 174.5, 507.54, 3.86, 0, 0, 0, 1, 60, 0, 1, '', 0, 'Woolly Pride: yak dung'),
(9963607, 2300811, 0, 0, 0, 1, 1, -6489.5, 199.5, 510.94, 0.79, 0, 0, 0, 1, 60, 0, 1, '', 0, 'Woolly Pride: yak dung'),
(9963608, 2300811, 0, 0, 0, 1, 1, -6490, 206, 510.94, 4.87, 0, 0, 0, 1, 60, 0, 1, '', 0, 'Woolly Pride: yak dung'),
(9963609, 2300811, 0, 0, 0, 1, 1, -6483.5, 203, 510.94, 3.64, 0, 0, 0, 1, 60, 0, 1, '', 0, 'Woolly Pride: yak dung');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164420 AND `source_type` = 0 AND `id` = 4;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164420, 0, 4, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ealdfrost Yak - On Gossip Hello - Close Gossip');
