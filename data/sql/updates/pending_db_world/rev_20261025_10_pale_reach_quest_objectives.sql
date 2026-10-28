-- Pale Reach: two quests could be turned in right after accepting them, because they have no objectives at all
-- (Player::CanCompleteQuest returns true for a quest without RequiredNpcOrGo/Item/...). Both rows come unchanged from
-- the Pale Reach export (rev_20261009_61_pale_reach_quests.sql, #7047/#8051).
-- Idempotent: UPDATEs set fixed values, every INSERT is preceded by a DELETE on its key.
-- Gossip texts are placeholders (no live text known).

-- ---------------------------------------------------------------------------------------------------------------
-- A. 175200 "Sins Beyond Mercy" (Confessor Mourn 164556): "Kill Brother Aldren, Paladin Abigail, and Samuel Crowe".
--    The three targets are friendly (FactionTemplate 12 / 1376) and IMMUNE_TO_PC|IMMUNE_TO_NPC (unit_flags 768).
--    While the quest is active, a gossip option turns the NPC hostile and it attacks (same pattern as the
--    Hallow Wind Initiates for 175013). Evade and respawn restore faction and immunity. Kill credit = own entry.
-- ---------------------------------------------------------------------------------------------------------------
UPDATE `quest_template` SET
  `RequiredNpcOrGo1` = 164994, `RequiredNpcOrGoCount1` = 1,
  `RequiredNpcOrGo2` = 164995, `RequiredNpcOrGoCount2` = 1,
  `RequiredNpcOrGo3` = 164996, `RequiredNpcOrGoCount3` = 1
WHERE `ID` = 175200;

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` IN (164994, 164995, 164996);
-- Abigail (questgiver of 175344) gets gossip next to her quests.
UPDATE `creature_template` SET `npcflag` = 3, `gossip_menu_id` = 1200460 WHERE `entry` = 164995;

DELETE FROM `npc_text` WHERE `ID` = 1200460;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES
(1200460, 'The dead do not rest in these crypts. Speak quickly.', 'The dead do not rest in these crypts. Speak quickly.', 1);
DELETE FROM `gossip_menu` WHERE `MenuID` = 1200460;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES (1200460, 1200460);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (1200458, 1200459, 1200460) AND `OptionID` = 0;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`) VALUES
(1200458, 0, 0, 'Confessor Mourn has passed the Light''s judgment on you, Samuel Crowe.', 0, 1, 1, 0, 0, 0, 0, '', 0),
(1200459, 0, 0, 'Confessor Mourn has passed the Light''s judgment on you, Brother Aldren.', 0, 1, 1, 0, 0, 0, 0, '', 0),
(1200460, 0, 0, 'Confessor Mourn has passed the Light''s judgment on you, Abigail.', 0, 1, 1, 0, 0, 0, 0, '', 0);

-- Option only while 175200 is in the log and not yet complete (CONDITION_QUESTTAKEN = 9).
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` IN (1200458, 1200459, 1200460) AND `SourceEntry` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 1200458, 0, 0, 0, 9, 0, 175200, 0, 0, 0, 0, 0, '', 'Samuel Crowe - judgment option only while Sins Beyond Mercy is active'),
(15, 1200459, 0, 0, 0, 9, 0, 175200, 0, 0, 0, 0, 0, '', 'Brother Aldren - judgment option only while Sins Beyond Mercy is active'),
(15, 1200460, 0, 0, 0, 9, 0, 175200, 0, 0, 0, 0, 0, '', 'Paladin Abigail - judgment option only while Sins Beyond Mercy is active');

-- Gossip -> close, faction 14, drop immunity, attack. Evade/respawn -> restore (SmartAI::JustRespawned restores the
-- faction only, not unit_flags, hence the extra RESPAWN event).
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` IN (164994, 164995, 164996);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164994, 0, 0, 1, 62, 0, 100, 0, 1200459, 0, 0, 0, 0, 0, 72,   0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Brother Aldren - On gossip option - Close gossip'),
(164994, 0, 1, 2, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0,  2,  14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Brother Aldren - Linked - Turn hostile'),
(164994, 0, 2, 3, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 19, 768, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Brother Aldren - Linked - Remove IMMUNE_TO_PC and IMMUNE_TO_NPC'),
(164994, 0, 3, 0, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 49,   0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Brother Aldren - Linked - Attack invoker'),
(164994, 0, 4, 5,  7, 0, 100, 0,       0, 0, 0, 0, 0, 0,  2,   0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Brother Aldren - On evade - Restore faction'),
(164994, 0, 5, 0, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 18, 768, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Brother Aldren - Linked - Restore IMMUNE_TO_PC and IMMUNE_TO_NPC'),
(164994, 0, 6, 0, 11, 0, 100, 0,       0, 0, 0, 0, 0, 0, 18, 768, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Brother Aldren - On respawn - Restore IMMUNE_TO_PC and IMMUNE_TO_NPC'),
(164995, 0, 0, 1, 62, 0, 100, 0, 1200460, 0, 0, 0, 0, 0, 72,   0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Paladin Abigail - On gossip option - Close gossip'),
(164995, 0, 1, 2, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0,  2,  14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Paladin Abigail - Linked - Turn hostile'),
(164995, 0, 2, 3, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 19, 768, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Paladin Abigail - Linked - Remove IMMUNE_TO_PC and IMMUNE_TO_NPC'),
(164995, 0, 3, 0, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 49,   0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Paladin Abigail - Linked - Attack invoker'),
(164995, 0, 4, 5,  7, 0, 100, 0,       0, 0, 0, 0, 0, 0,  2,   0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Paladin Abigail - On evade - Restore faction'),
(164995, 0, 5, 0, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 18, 768, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Paladin Abigail - Linked - Restore IMMUNE_TO_PC and IMMUNE_TO_NPC'),
(164995, 0, 6, 0, 11, 0, 100, 0,       0, 0, 0, 0, 0, 0, 18, 768, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Paladin Abigail - On respawn - Restore IMMUNE_TO_PC and IMMUNE_TO_NPC'),
(164996, 0, 0, 1, 62, 0, 100, 0, 1200458, 0, 0, 0, 0, 0, 72,   0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Samuel Crowe - On gossip option - Close gossip'),
(164996, 0, 1, 2, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0,  2,  14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Samuel Crowe - Linked - Turn hostile'),
(164996, 0, 2, 3, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 19, 768, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Samuel Crowe - Linked - Remove IMMUNE_TO_PC and IMMUNE_TO_NPC'),
(164996, 0, 3, 0, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 49,   0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Samuel Crowe - Linked - Attack invoker'),
(164996, 0, 4, 5,  7, 0, 100, 0,       0, 0, 0, 0, 0, 0,  2,   0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Samuel Crowe - On evade - Restore faction'),
(164996, 0, 5, 0, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 18, 768, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Samuel Crowe - Linked - Restore IMMUNE_TO_PC and IMMUNE_TO_NPC'),
(164996, 0, 6, 0, 11, 0, 100, 0,       0, 0, 0, 0, 0, 0, 18, 768, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Samuel Crowe - On respawn - Restore IMMUNE_TO_PC and IMMUNE_TO_NPC');

-- ---------------------------------------------------------------------------------------------------------------
-- B. 175128 "The Last Captives" (Rockrend Citizen 164359 -> Mountaineer Thandel 164012): "rescue the Rockrend
--    prisoners". The six prisoners 164361, 164362, 164364-164367 (one spawn each in the murloc village, respawn
--    120 s) had no gossip and no script. While the quest is active a gossip option frees the prisoner: shared credit
--    164361 for the player, then the prisoner despawns (back after its 120 s respawn time). 6 of 6 required.
-- ---------------------------------------------------------------------------------------------------------------
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 164361, `RequiredNpcOrGoCount1` = 6,
  `ObjectiveText1` = 'Rockrend prisoner freed'
WHERE `ID` = 175128;

UPDATE `creature_template` SET `AIName` = 'SmartAI', `npcflag` = 1, `gossip_menu_id` = 1200461
WHERE `entry` IN (164361, 164362, 164364, 164365, 164366, 164367);

DELETE FROM `npc_text` WHERE `ID` = 1200461;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES
(1200461, '<The prisoner tugs at the ropes and looks at you with desperate hope.>', '<The prisoner tugs at the ropes and looks at you with desperate hope.>', 1);
DELETE FROM `gossip_menu` WHERE `MenuID` = 1200461;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES (1200461, 1200461);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 1200461;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`) VALUES
(1200461, 0, 0, 'Cut the ropes. Thandel is waiting for you at the mine.', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 1200461;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 1200461, 0, 0, 0, 9, 0, 175128, 0, 0, 0, 0, 0, '', 'Rockrend Prisoner - free option only while The Last Captives is active');

DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` IN (164361, 164362, 164364, 164365, 164366, 164367);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164361, 0, 0, 1, 62, 0, 100, 0, 1200461, 0, 0, 0, 0, 0, 72,      0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - On gossip option - Close gossip'),
(164361, 0, 1, 2, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 33, 164361, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - Linked - Quest credit (The Last Captives)'),
(164361, 0, 2, 0, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 41,   1500, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - Linked - Despawn (freed)'),
(164362, 0, 0, 1, 62, 0, 100, 0, 1200461, 0, 0, 0, 0, 0, 72,      0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - On gossip option - Close gossip'),
(164362, 0, 1, 2, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 33, 164361, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - Linked - Quest credit (The Last Captives)'),
(164362, 0, 2, 0, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 41,   1500, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - Linked - Despawn (freed)'),
(164364, 0, 0, 1, 62, 0, 100, 0, 1200461, 0, 0, 0, 0, 0, 72,      0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - On gossip option - Close gossip'),
(164364, 0, 1, 2, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 33, 164361, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - Linked - Quest credit (The Last Captives)'),
(164364, 0, 2, 0, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 41,   1500, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - Linked - Despawn (freed)'),
(164365, 0, 0, 1, 62, 0, 100, 0, 1200461, 0, 0, 0, 0, 0, 72,      0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - On gossip option - Close gossip'),
(164365, 0, 1, 2, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 33, 164361, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - Linked - Quest credit (The Last Captives)'),
(164365, 0, 2, 0, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 41,   1500, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - Linked - Despawn (freed)'),
(164366, 0, 0, 1, 62, 0, 100, 0, 1200461, 0, 0, 0, 0, 0, 72,      0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - On gossip option - Close gossip'),
(164366, 0, 1, 2, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 33, 164361, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - Linked - Quest credit (The Last Captives)'),
(164366, 0, 2, 0, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 41,   1500, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - Linked - Despawn (freed)'),
(164367, 0, 0, 1, 62, 0, 100, 0, 1200461, 0, 0, 0, 0, 0, 72,      0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - On gossip option - Close gossip'),
(164367, 0, 1, 2, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 33, 164361, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - Linked - Quest credit (The Last Captives)'),
(164367, 0, 2, 0, 61, 0, 100, 0,       0, 0, 0, 0, 0, 0, 41,   1500, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockrend Prisoner - Linked - Despawn (freed)');
