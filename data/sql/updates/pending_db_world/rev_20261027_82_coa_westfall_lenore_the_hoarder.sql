-- Lenore the Hoarder (991515): her loot set on human female 50, both loot knives (their ItemDisplayInfo rows
-- carry the red and purple glows), dual wield, and the realm's Net, Sinister Strike and Fierce Blow.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 991515;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(991515, 0, 50, 1, 1, 0);

DELETE FROM `creature_display_preset` WHERE `entry` = 991515;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`,
  `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`,
  `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(991515, 50, 1, 1, 4, 7, 3, 13, 3, 0, 0, 34851, 0, 0, 14886, 6715, 16999, 7227, 0, 13483, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 991515;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(991515, 1, 2089838, 2089839, 0, 0);

UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9950107 AND `id` = 991515;

UPDATE `creature_template` SET `AIName` = 'SmartAI', `flags_extra` = `flags_extra` | 0x800 WHERE `entry` = 991515;

DELETE FROM `creature_text` WHERE `CreatureID` = 991515;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
  `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(991515, 0, 0, 'HEY! Get away from my stuff!!!', 12, 0, 100, 0, 0, 0, 0, 0, 'Lenore the Hoarder - Aggro');

-- Sinister Strike 992957 costs energy, which creatures do not have: cast it ignoring power cost only.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 991515 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(991515, 0, 0, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Lenore the Hoarder - On Aggro - Say Line 0'),
(991515, 0, 1, 0, 0, 0, 100, 0, 500, 1000, 24000, 26000, 0, 0, 11, 12024, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Lenore the Hoarder - In Combat - Cast ''Net'''),
(991515, 0, 2, 0, 0, 0, 100, 0, 3000, 5000, 4000, 6000, 0, 0, 11, 992957, 2, 4, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Lenore the Hoarder - In Combat - Cast ''Sinister Strike'''),
(991515, 0, 3, 0, 0, 0, 100, 0, 6000, 8000, 7000, 9000, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Lenore the Hoarder - In Combat - Cast ''Fierce Blow''');
