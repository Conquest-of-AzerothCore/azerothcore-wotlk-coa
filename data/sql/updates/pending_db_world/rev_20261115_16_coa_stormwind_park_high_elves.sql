-- Stormwind Park high elves from realm footage (RIEMlZSgbQw 1:50:33-1:50:35, VGzezmaiv8A 21:06-21:09,
-- AscenSS 072626-084931). Velithra wears the Tilted Cliffs elves' robe set; Aerendyl a white shirt under a black
-- vest with black trousers (closest client items); Zaradiel kneels by the tents. High elves take blue-eyed skins.
DELETE FROM `creature_display_preset` WHERE `entry` IN (164108, 164485);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`,
    `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`,
    `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164108, 15476, 10, 0, 1, 22, 3, 9, 7, 0, 0, 0, 0, 7889, 19008, 0, 10097, 6663, 0, 0, 0, 0),
(164485, 15475, 10, 1, 1, 22, 1, 5, 0, 0, 0, 0, 20583, 0, 26300, 11364, 0, 22210, 0, 0, 0, 0);

DELETE FROM `creature_addon` WHERE `guid` = 9960108;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
    `auras`) VALUES
(9960108, 0, 0, 8, 1, 0, 0, '');
