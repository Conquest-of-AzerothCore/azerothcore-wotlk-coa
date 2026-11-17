-- Snowveil Cemetery mourners from the realm (nameplates RIEMlZSgbQw 8:29:28; body views AscenSS 071326-053711/053728):
-- Thorin in a black velvet robe with long white hair, Brynna in a black bodice with flared sleeves and a black bun.
-- Bilna Stonefist's dress hides her feet in every view; she gets the shoes of her dress's set (Dress_B_03Black).
DELETE FROM `creature_display_preset` WHERE (`entry`, `display_id`) IN ((164453, 54), (164456, 53), (164458, 54));
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164453, 54, 3, 1, 1, 2, 4, 5, 9, 0, 0, 0, 0, 10095, 14974, 0, 0, 7678, 0, 0, 0, 0),
(164456, 53, 3, 0, 1, 2, 3, 1, 14, 2, 0, 0, 0, 0, 16459, 0, 0, 16492, 0, 0, 0, 0),
(164458, 54, 3, 1, 1, 8, 4, 4, 5, 0, 0, 0, 0, 0, 149042, 0, 10097, 6663, 0, 0, 0, 0);
