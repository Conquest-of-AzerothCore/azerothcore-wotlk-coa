-- Seloria (164285) by the left Namarien orb wears a long dark violet gown (VGzezmaiv8A 20:29, V10AMkhYl6c 9:12),
-- not the yellow robe; look set in game by the user.
DELETE FROM `creature_display_preset` WHERE (`entry`, `display_id`) IN ((164285, 15475));
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`,
    `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`,
    `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164285, 15475, 10, 1, 1, 24, 2, 5, 12, 0, 0, 0, 0, 0, 9408, 0, 0, 155705, 0, 0, 0, 0);
