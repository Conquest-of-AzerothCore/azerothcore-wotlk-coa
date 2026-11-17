-- Ambassador Thargas Anvilmar from his quest-window view (RIEMlZSgbQw 8:06:04-8:07:00): top-knot, long brown beard,
-- Soulbreaker's Court tunic (133640); trousers and boots are close, the small shoulder piece is unidentified.
-- His spawn stood 0.12 below the throne hall floor.
DELETE FROM `creature_display_preset` WHERE `entry` = 164389;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`,
    `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`,
    `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164389, 53, 3, 0, 1, 4, 7, 8, 6, 0, 0, 0, 0, 0, 133640, 0, 9413, 2162, 0, 0, 0, 0);

UPDATE `creature` SET `position_z` = 576.881 WHERE `guid` = 9962261 AND `id` = 164389;
