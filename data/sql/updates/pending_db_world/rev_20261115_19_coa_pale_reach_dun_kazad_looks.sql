-- Dun Kazad vendors from realm footage (RIEMlZSgbQw 8:09-9:10, AscenSS 071326-051951); closest client items.
-- Kardu replaces the placeholder kit, Ellerdin is a dwarf woman, Ginnad has black side pigtails;
-- Kardu's, Ellerdin's and Ginnad's looks were finished in game.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 54 WHERE `CreatureID` = 164411 AND `Idx` = 0;

DELETE FROM `creature_display_preset` WHERE `entry` IN (164410, 164411, 164417);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`,
    `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`,
    `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164410, 54, 3, 1, 1, 2, 3, 3, 5, 0, 0, 0, 0, 147258, 57669, 3408, 54935, 1246, 0, 57667, 0, 0),
(164411, 54, 3, 1, 1, 0, 5, 1, 9, 0, 0, 0, 0, 0, 20478, 0, 143945, 142933, 0, 0, 0, 0),
(164417, 53, 3, 0, 1, 6, 7, 10, 3, 8, 0, 0, 0, 12457, 0, 22377, 83762, 155678, 0, 11063, 0, 0);
