-- Gryphon Master Stonefeather (164405) wore the shared placeholder kit; the realm footage shows only dark armour with
-- gold trim and a pale beard (RIEMlZSgbQw 8:15:31). Look set in game by the user, with the Dun Kazad tabard.
DELETE FROM `creature_display_preset` WHERE `entry` = 164405;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`,
    `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`,
    `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164405, 53, 3, 0, 1, 6, 7, 10, 6, 4, 0, 0, 67771, 7306, 67891, 54962, 6528, 2162, 0, 57667, 0, 170324);
