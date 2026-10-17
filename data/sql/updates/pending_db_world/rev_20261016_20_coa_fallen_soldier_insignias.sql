-- Tokens of Sacrifice (175050), as on live (user): clicking a dead Graysky Soldier (164058, the sniffed corpse type at Frostmane
-- Ambush and Kharadol Bridge) gives a Graysky Guard Insignia to a player on the quest. Each body can be searched again after
-- 2 minutes. The four bodies at Frostmane Ambush lie dead like the ones on the bridge.
UPDATE `creature_template` SET `npcflag` = `npcflag` | 1, `AIName` = 'SmartAI' WHERE `entry` = 164058;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164058 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164058, 0, 0, 1, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 56, 559879, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Graysky Soldier (dead) - On Gossip Hello - Add Item ''Graysky Guard Insignia'''),
(164058, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Graysky Soldier (dead) - Linked - Close Gossip'),
(164058, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Graysky Soldier (dead) - Linked - Remove Npc Flag Gossip'),
(164058, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 120000, 120000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Graysky Soldier (dead) - Linked - Create Timed Event 1 (2 min)'),
(164058, 0, 4, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Graysky Soldier (dead) - On Timed Event 1 - Add Npc Flag Gossip');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = 164058 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 164058, 0, 0, 9, 0, 175050, 0, 0, 0, 0, 0, '', 'Dead Graysky Soldier gives an insignia only to players on Tokens of Sacrifice');
DELETE FROM `creature_addon` WHERE `guid` IN (9981317, 9981318, 9981322, 9981356);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9981317, 0, 0, 0, 1, 0, 0, '29266'),
(9981318, 0, 0, 0, 1, 0, 0, '29266'),
(9981322, 0, 0, 0, 1, 0, 0, '29266'),
(9981356, 0, 0, 0, 1, 0, 0, '29266');
