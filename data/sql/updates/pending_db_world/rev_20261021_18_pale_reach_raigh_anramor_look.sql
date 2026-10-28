-- Raigh Anramor (164047) wore a guessed chef's hat and white shirt. On the realm (Redthedeer VOD Day 2 dialogue window,
-- 00:57:42 and 01:02:48, beside a player in Ealdir Attire; screenshot 071226-002814) he wears the Ealdir outfit of
-- 164049 under a wolf-head helm (Garadar Defender's Helm, 145479), with Blood-Soaked Bandages (49652) on the body and
-- long brown hair. Face and beard are hidden by the helm and kept from the Ealdir look.
UPDATE `creature_display_preset` SET `race` = 1, `gender` = 0, `class` = 1, `skin` = 1, `face` = 3, `hair` = 10, `haircolor` = 19,
    `facialhair` = 3, `guild_id` = 0, `item_head` = 145479, `item_shoulders` = 136582, `item_body` = 49652, `item_chest` = 136568,
    `item_waist` = 0, `item_legs` = 42754, `item_feet` = 48975, `item_wrists` = 0, `item_hands` = 157981, `item_back` = 0,
    `item_tabard` = 0 WHERE `entry` = 164047 AND `display_id` = 49;
