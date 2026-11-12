-- Aelion Brightspring (164250), Seralyth Dawnswell (164251) and Naeris Brightspring (164486), the high elves at the
-- spring sanctuary, wore the import's bare-chested placeholder. On the realm they wear Sanadriel's robes (user, who
-- played it live; AscenSS 071226-043040, -043107, video 6QNRME4U5pY 0:02:40 and 0:03:43-0:03:46, V10AMkhYl6c 0:05:36):
-- the cream robe with dark bands and a teal hem under blue shoulders, on Sanadriel's blue-eyed skin. Aelion has a red
-- topknot and carries a blue crystal staff, Seralyth sits, and Naeris is a dark-haired woman with the same staff.
-- Their faces are too small in the footage, so face, beard and Seralyth's and Naeris's hair styles are not certain.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (164250, 164251, 164486);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164250, 0, 15476, 1, 1, 0),
(164251, 0, 15476, 1, 1, 0),
(164486, 0, 15475, 1, 1, 0);

DELETE FROM `creature_display_preset` WHERE `entry` IN (164250, 164251, 164486);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164250, 15476, 10, 0, 1, 38, 0, 12, 9, 0, 0, 0, 20583, 0, 26300, 11364, 0, 22210, 0, 0, 0, 0),
(164251, 15476, 10, 0, 1, 38, 0, 13, 20, 0, 0, 0, 20583, 0, 26300, 11364, 0, 22210, 0, 0, 0, 0),
(164486, 15475, 10, 1, 1, 38, 0, 11, 20, 0, 0, 0, 20583, 0, 26300, 11364, 0, 22210, 0, 0, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (164250, 164486) AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164250, 1, 2950, 0, 0, 0),
(164486, 1, 2950, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9960752 AND `id` = 164250;
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9960749 AND `id` = 164486;

DELETE FROM `creature_addon` WHERE `guid` = 9960751;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960751, 0, 0, 1, 1, 0, 0, '');
