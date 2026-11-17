-- Caelorn (164289) wore an unsourced fel-tattoo starter outfit. wJ2j4NOgjRI 3:17:28-3:17:30 shows him in the Namarien
-- library in a navy full-length robe with a gold hip band, holding a silver staff with a white crystal head.
-- Closest client items: Robe of the Archmage (Robe_C_01Blue) and Guiding Stave of Wisdom, worn on his back; blond
-- hair as set by the user.
DELETE FROM `creature_display_preset` WHERE (`entry`, `display_id`) IN ((164289, 15476));
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`,
    `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`,
    `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164289, 15476, 10, 0, 1, 24, 3, 6, 7, 0, 0, 0, 0, 0, 19718, 0, 0, 142933, 0, 0, 0, 0);
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164289 AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164289, 1, 11932, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9960130 AND `id` = 164289;
DELETE FROM `creature_addon` WHERE `guid` = 9960130;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960130, 0, 0, 0, 0, 0, 0, '');
