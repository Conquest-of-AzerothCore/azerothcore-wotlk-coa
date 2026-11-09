-- Selithra (164280) in Namarien Sanctuary, dressed by the user in game: a high elf with blue eyes (skin 24) in black
-- robe shoulders (15184), the purple Lesser Wizard's Robe (9408), a purple sash (5683) and red cloth gloves (14740),
-- with the Staff of Jordan (873) carried sheathed on her back (sheath state 0).
DELETE FROM `creature_display_preset` WHERE `entry` = 164280 AND `display_id` = 15475;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164280, 15475, 10, 1, 1, 24, 0, 3, 18, 4, 0, 0, 15184, 0, 9408, 5683, 0, 0, 0, 14740, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164280 AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164280, 1, 873, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9999001 AND `id` = 164280;

DELETE FROM `creature_addon` WHERE `guid` = 9999001;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9999001, 0, 0, 0, 0, 0, 0, '');
