-- Lord Sermon Spada's boots drew bright green: display 54748 uses DXT-compressed body textures, which the client
-- cannot composite onto a character. 54835 is the same Gilneas noble boot with palettized textures (#8117).
UPDATE `creature_display_preset` SET `item_feet` = 54835 WHERE `entry` = 164215 AND `display_id` = 49;
