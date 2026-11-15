-- Innkeeper Aleorina (164295) in Namarien Sanctuary wore a stock yellow robe. Live (V10AMkhYl6c 4:43, as identified
-- by the user) she is a blue-eyed high elf with a bare midriff: the Corrupted Coilfang Shirt's sleeves and top without
-- its lower torso (Cloth_A_08Gray AU/TU, 25590) over the green skirt of the Blood Robes (Robe_Horde_A_02Dark legs,
-- 25732, which keeps the top visible). Face and hair set by the user; skin 22 is a light blood elf skin with the blue
-- high elf eyes.
DELETE FROM `creature_display_preset` WHERE `entry` = 164295 AND `display_id` = 15475;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164295, 15475, 10, 1, 1, 22, 1, 11, 8, 0, 0, 0, 0, 25590, 0, 0, 25732, 0, 0, 0, 0, 0);
