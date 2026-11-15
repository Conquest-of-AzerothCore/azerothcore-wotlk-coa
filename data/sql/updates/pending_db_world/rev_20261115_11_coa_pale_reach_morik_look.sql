-- Morik Runaferro (164638) from Redthedeer's dialogue view (RIEMlZSgbQw 8:09:25, 9:10:27) and AscenSS 071326-051951:
-- braided beard, brown leather vest and studded belt, red sleeves, gauntlets, grey-olive trousers, gold pauldrons.
-- Closest client items; the pauldrons (82953) are a stand-in for the realm's plainer gold pair.
DELETE FROM `creature_display_preset` WHERE `entry` = 164638;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`,
    `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`,
    `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164638, 53, 3, 0, 1, 7, 4, 6, 12, 2, 0, 0, 82953, 147121, 63148, 54962, 54937, 54936, 0, 59523, 0, 0);
