-- Arion (164281), the Namarien Sanctuary arcane goods vendor, dressed by the user in game: a high elf with blue eyes
-- (skin 22) in purple Mystical Armor (22278), a gold mail belt (25611), grey trousers (9356) and red leather boots
-- (13338).
DELETE FROM `creature_display_preset` WHERE `entry` = 164281 AND `display_id` = 15476;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164281, 15476, 10, 0, 1, 22, 0, 3, 1, 0, 0, 0, 0, 0, 22278, 25611, 9356, 13338, 0, 0, 0, 0);
