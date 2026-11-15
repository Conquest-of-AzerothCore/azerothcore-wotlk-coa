-- Aldaria (164318) in Namarien Sanctuary, dressed by the user in game: a high elf with blue eyes (skin 25) in a blue
-- Cloth_Blood_A_01 robe top (32072), green sash (6766), purple High Councillor's pants (21829) and black cloth boots
-- (12265).
DELETE FROM `creature_display_preset` WHERE `entry` = 164318 AND `display_id` = 15475;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164318, 15475, 10, 1, 1, 25, 2, 5, 1, 0, 0, 0, 0, 0, 32072, 6766, 21829, 12265, 0, 0, 0, 0);
