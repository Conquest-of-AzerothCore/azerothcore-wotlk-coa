-- Maelith (164284) and Miralyn (164291) in the Hall of Stories both wore the import's placeholder: a green-eyed woman
-- in an orange dress. wJ2j4NOgjRI 3:14:36-3:14:37 and 3:15:04 show Maelith as a man standing before the bench in a
-- teal long-sleeved shirt, dark belt, violet trousers and dark boots, pale short hair, gesturing as he talks, and
-- Miralyn as a woman with auburn hair in a dark green robe with a pale hem and lighter shoulders, seated facing him
-- (her seat is set in rev_20261108_9995). Both are blue-eyed high elves (skin 22). They are about 150 px tall in the
-- footage: garment kinds and colours are matched, the exact pieces, faces and hair styles are not. Miralyn carries
-- a staff across her back with a dark knob at its top end; the user knows it as a staff with a green orb and picked
-- Neltharian Channeler's Rod (99915) in the in-game wardrobe. She carries it sheathed.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 164284;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164284, 0, 15476, 1, 1, 0);

DELETE FROM `creature_display_preset` WHERE `entry` IN (164284, 164291);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164284, 15476, 10, 0, 1, 22, 0, 1, 25, 0, 0, 0, 0, 0, 8364, 5740, 49573, 1804, 0, 0, 0, 0),
(164291, 15475, 10, 1, 1, 22, 0, 8, 6, 0, 0, 0, 9962, 0, 9674, 0, 0, 3257, 0, 0, 0, 0);

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164284;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164284 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164284, 0, 0, 0, 1, 0, 100, 0, 3000, 8000, 6000, 12000, 0, 0, 5, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Maelith - Out of Combat - Play Emote Talk');

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164291 AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164291, 1, 99915, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9960150 AND `id` = 164291;
UPDATE `creature_addon` SET `bytes2` = 0 WHERE `guid` = 9960150;
