-- Ealdir Attire (365016/365017) turns a player into Ealdir Male 164535 or Ealdir Female 164536. Their displays
-- (142949/142950) draw the body from a baked NPC texture that a player model leaves invisible, so only the weapon
-- showed. Outfit presets let coa_transform_presets dress the player instead: the male look is the Dead Ealdmaine
-- Ealdir's, the female look takes the face and hair of extra display 500034 with the same outfit.
DELETE FROM `creature_display_preset` WHERE `entry` IN (164535, 164536);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164535, 49, 1, 0, 1, 8, 3, 7, 0, 3, 0, 136581, 136582, 0, 136568, 0, 42754, 48975, 0, 157981, 0, 0),
(164536, 50, 1, 1, 1, 8, 9, 9, 9, 9, 0, 136581, 136582, 0, 136568, 0, 42754, 48975, 0, 157981, 0, 0);
