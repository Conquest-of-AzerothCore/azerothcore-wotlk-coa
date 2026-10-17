-- "Light's Warmth" in the Snowsong Valley watchtower, set up from the user's screenshots of live and of this server:
-- * the Exhausted Refugees get their live talk window and "<You chant a brief prayer.>" option, which counts as a prayer
--   offered (5 needed); a refugee who has been prayed over can be prayed over again two minutes later;
-- * they lie, sit and kneel as on live, as dwarves without the baker's hat;
-- * the Watchtower Bonfire becomes the clickable Cozy Fire the quest feeds logs into (5 needed), three of them placed
--   among the refugees.
DELETE FROM `npc_text` WHERE `ID` = 9920104;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES
(9920104, '<His breathing is faint. At a glance, he appears to be a lifeless heap. Judging by the crimson trail he left behind, you would say he has lost far too much blood.>', '<His breathing is faint. At a glance, he appears to be a lifeless heap. Judging by the crimson trail he left behind, you would say he has lost far too much blood.>', 1);
DELETE FROM `gossip_menu` WHERE `MenuID` = 9920104;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(9920104, 9920104);
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 9920104;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`) VALUES
(9920104, 0, 0, '<You chant a brief prayer.>', 0, 1, 1, 0, 0, 0, 0, '', 0);
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 9920104 AND `SourceEntry` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 9920104, 0, 0, 0, 9, 0, 175056, 0, 0, 0, 0, 0, '', 'Exhausted Refugee - pray only while on Light''s Warmth');
UPDATE `creature_template` SET `gossip_menu_id` = 9920104, `npcflag` = `npcflag` | 1, `AIName` = 'SmartAI' WHERE `entry` IN (164068, 164069);
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (164068, 164069) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164068, 0, 0, 1, 62, 0, 100, 0, 9920104, 0, 0, 0, 0, 0, 33, 164068, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Gossip Option 0 Selected - Quest Credit ''Prayers offered'''),
(164068, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - Linked - Close Gossip'),
(164068, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - Linked - Remove Npc Flag Gossip'),
(164068, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 120000, 120000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - Linked - Create Timed Event 1 (2 min)'),
(164068, 0, 4, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Timed Event 1 - Add Npc Flag Gossip'),
(164069, 0, 0, 1, 62, 0, 100, 0, 9920104, 0, 0, 0, 0, 0, 33, 164068, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Gossip Option 0 Selected - Quest Credit ''Prayers offered'''),
(164069, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - Linked - Close Gossip'),
(164069, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - Linked - Remove Npc Flag Gossip'),
(164069, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 120000, 120000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - Linked - Create Timed Event 1 (2 min)'),
(164069, 0, 4, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Timed Event 1 - Add Npc Flag Gossip');
DELETE FROM `creature_addon` WHERE `guid` IN (9981400, 9981404, 9981409, 9981411, 9981401, 9981402, 9981403, 9981407, 9981399, 9981408, 9981410);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9981400, 0, 0, 3, 1, 0, 0, ''),
(9981404, 0, 0, 3, 1, 0, 0, ''),
(9981409, 0, 0, 3, 1, 0, 0, ''),
(9981411, 0, 0, 3, 1, 0, 0, ''),
(9981401, 0, 0, 1, 1, 0, 0, ''),
(9981402, 0, 0, 1, 1, 0, 0, ''),
(9981403, 0, 0, 1, 1, 0, 0, ''),
(9981407, 0, 0, 1, 1, 0, 0, ''),
(9981399, 0, 0, 8, 1, 0, 0, ''),
(9981408, 0, 0, 8, 1, 0, 0, ''),
(9981410, 0, 0, 8, 1, 0, 0, '');
UPDATE `creature_display_preset` SET `race` = 3, `display_id` = 53, `item_head` = 0 WHERE `entry` IN (164068, 164069) AND `display_id` = 49;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 53 WHERE `CreatureID` IN (164068, 164069) AND `CreatureDisplayID` = 49;
UPDATE `gameobject_template` SET `type` = 10, `displayId` = 199, `name` = 'Cozy Fire', `Data1` = 175056 WHERE `entry` = 2300668;
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9963437 AND 9963439;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9963437, 2300668, 0, 0, 0, 1, 1, -7006.5, 505.5, 350.4, 0, 0, 0, 0, 1, 300, 0, 1, 'Cozy Fire, Snowsong Valley watchtower (Light''s Warmth)'),
(9963438, 2300668, 0, 0, 0, 1, 1, -6996.0, 499.5, 350.4, 0, 0, 0, 0, 1, 300, 0, 1, 'Cozy Fire, Snowsong Valley watchtower (Light''s Warmth)'),
(9963439, 2300668, 0, 0, 0, 1, 1, -6999.8, 506.5, 350.4, 0, 0, 0, 0, 1, 300, 0, 1, 'Cozy Fire, Snowsong Valley watchtower (Light''s Warmth)');
