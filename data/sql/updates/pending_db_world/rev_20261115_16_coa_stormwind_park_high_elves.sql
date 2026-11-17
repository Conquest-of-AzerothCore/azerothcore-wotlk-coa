-- Stormwind Park high elves from realm footage (RIEMlZSgbQw 1:50:33-1:50:35, VGzezmaiv8A 21:06-21:09,
-- AscenSS 072626-084931), finished in game by the user: Velithra wears the Tilted Cliffs elves' robe set,
-- Aerendyl a white shirt under a black vest, Zaradiel is a woman sitting by the tents.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 15475 WHERE `CreatureID` = 164106 AND `Idx` = 0;

DELETE FROM `creature_display_preset` WHERE `entry` IN (164106, 164108, 164485);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`,
    `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`,
    `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164106, 15475, 10, 1, 1, 22, 3, 6, 5, 0, 0, 0, 0, 0, 12946, 0, 143945, 142933, 0, 0, 0, 0),
(164108, 15476, 10, 0, 1, 22, 3, 3, 7, 0, 0, 0, 0, 10038, 11690, 0, 10097, 6663, 0, 0, 0, 0),
(164485, 15475, 10, 1, 1, 22, 1, 7, 11, 0, 0, 0, 20583, 0, 26300, 11364, 0, 22210, 0, 0, 0, 0);

DELETE FROM `creature_addon` WHERE `guid` = 9960108;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
    `auras`) VALUES
(9960108, 0, 0, 1, 1, 0, 0, '');
