-- Alta'zin the Ascended (164071) was a bare stock ice troll on foot. On the live realm (videos o6AaRPzuChg 00:00:04,
-- VHJ6iQApHwc 00:11:19, HIbr82QgX6w 01:48:33) he is a blue troll in Zul'Aman plate (skull-cluster shoulders, shin
-- clasps over bare feet) riding Zelezak, the Drakkari sabre (display 141870), with a pale axe, a narrow dark
-- serrated cloak, and the Bloodhunter Visage mask the contributor recalls. The wraps, gauntlets, axe and the colours
-- of the clasps and cloak are near picks. He holds a Zul'Gurub one-handed axe (60822) in each hand, picked by the
-- contributor from renders of every plain axe against the swing at HIbr82QgX6w 01:48:38.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 164071;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164071, 0, 1478, 1.2, 1, 0);

DELETE FROM `creature_display_preset` WHERE `entry` = 164071;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164071, 1478, 8, 0, 1, 23, 0, 7, 2, 0, 0, 144599, 46438, 0, 167408, 0, 167411, 45541, 0, 46414, 127876, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164071 AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164071, 1, 60822, 60822, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9961395 AND `id` = 164071;

DELETE FROM `creature_addon` WHERE `guid` = 9961395;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9961395, 0, 141870, 0, 1, 0, 0, '');
