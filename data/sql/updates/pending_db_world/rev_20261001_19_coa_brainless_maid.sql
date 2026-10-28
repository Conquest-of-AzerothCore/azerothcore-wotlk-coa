-- Brainless Maid 161754 (An Unspeakable Secret 1660026), from CoA footage described by the playtester: a Forsaken
-- woman sitting and gazing at the water, who speaks when engaged. Her CoA display is not in the client; the
-- stand-in 1200 gives way to a Forsaken woman (display 58 with a preset, like the class trainers) in the
-- Buccaneer's Robes appearance (item display 22298), with long full hair (style 4, the longest Forsaken female
-- hair mesh) in pale blonde (colour 13) (author's choice; INFERRED). rev_20260926_10 spawned her twice, at CoA's
-- track point ST8684 and at a Questie point 23 yd away; the author saw one maid on CoA, so the Questie copy goes.
-- She sits a little up the lake shore from ST8684 at the author's spot, facing the water 5 yd to the north-west
-- (surface.liquid). SmartAI on AGGRO (4), say (12).
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161754;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(161754, 0, 58, 1, 1);
DELETE FROM `creature_display_preset` WHERE `entry` = 161754;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`,
    `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`,
    `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(161754, 58, 5, 1, 1, 3, 8, 4, 13, 0, 0, 0, 0, 0, 22298, 0, 0, 0, 0, 0, 0, 0);
DELETE FROM `creature_template_addon` WHERE `entry` = 161754;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(161754, 0, 0, 1, 0, 0, 0, '');
DELETE FROM `creature` WHERE `guid` = 9010009 AND `id` = 161754;
UPDATE `creature` SET `position_x` = 1914.03, `position_y` = 2003.58, `position_z` = 157.553, `orientation` = 0.79
    WHERE `guid` = 9010008 AND `id` = 161754;
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 161754;
DELETE FROM `creature_text` WHERE `CreatureID` = 161754;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`)
VALUES
(161754, 0, 0, 'My Lady Priscilla... I think she needs me... What was it I came here to do?', 12, 100, 'Brainless Maid - aggro (CoA footage)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 161754 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(161754, 0, 0, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Brainless Maid - On Aggro - Say Line 0');
