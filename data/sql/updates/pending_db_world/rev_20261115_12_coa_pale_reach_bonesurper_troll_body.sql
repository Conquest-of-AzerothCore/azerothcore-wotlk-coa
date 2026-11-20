-- Bonesurper Troll (164431): the ice troll body (race 43) has low-resolution skins the client cannot dress, so it drew
-- black. The same mask, tunic and skirt (MD0GT_RsHQs night fight) now go on a blue troll, as Frostmane Reaper does.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 1478 WHERE `CreatureID` = 164431 AND `Idx` = 0;

DELETE FROM `creature_display_preset` WHERE (`entry`, `display_id`) IN ((164431, 26873), (164431, 1478));
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`,
    `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`,
    `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164431, 1478, 8, 0, 1, 23, 0, 3, 5, 0, 0, 5072, 0, 0, 19720, 0, 126796, 0, 0, 0, 0, 0);
