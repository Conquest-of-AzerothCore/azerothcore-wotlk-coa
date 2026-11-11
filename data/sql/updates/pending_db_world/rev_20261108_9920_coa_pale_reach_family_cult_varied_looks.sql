-- The Family Zealots (164310) and Cultists (164312) all wore one male high elf face. Each spawn now rolls male or
-- female (two models at equal odds, each with the cult's outfit) and its own high elf look: a blue-eyed skin (22-25,
-- 38-39, 50-51), any face, a hair style, a natural hair colour and earrings or marks. Hair style 19 is left out for
-- women; it is not bald on the HD model. Both outfits are written here in full (the zealot's from rev_20261108_9910),
-- so this file does not depend on the order the two land in.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (164310, 164312);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164310, 0, 15476, 1, 1, 0),
(164310, 1, 15475, 1, 1, 0),
(164312, 0, 15476, 1, 1, 0),
(164312, 1, 15475, 1, 1, 0);

DELETE FROM `creature_display_preset` WHERE `entry` IN (164310, 164312);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164310, 15476, 10, 0, 1, 24, 0, 1, 21, 3, 0, 11992, 45136, 0, 74340, 0, 0, 74328, 0, 46011, 74310, 0),
(164310, 15475, 10, 1, 1, 22, 0, 0, 0, 0, 0, 11992, 45136, 0, 74340, 0, 0, 74328, 0, 46011, 74310, 0),
(164312, 15476, 10, 0, 1, 24, 0, 1, 21, 3, 0, 48193, 45136, 0, 74340, 0, 0, 74328, 0, 46011, 74310, 0),
(164312, 15475, 10, 1, 1, 22, 0, 0, 0, 0, 0, 48193, 45136, 0, 74340, 0, 0, 74328, 0, 46011, 74310, 0);

DELETE FROM `creature_display_preset_variety` WHERE `entry` IN (164310, 164312);
INSERT INTO `creature_display_preset_variety` (`entry`, `gender`, `skins`, `faces`, `hair_styles`, `hair_colors`, `facial_hairs`) VALUES
(164310, 0, '22-25 38 39 50 51', '0-24', '0-15', '0-9', '0-9'),
(164310, 1, '22-25 38 39 50 51', '0-24', '0-18', '0-9', '0-10'),
(164312, 0, '22-25 38 39 50 51', '0-24', '0-15', '0-9', '0-9'),
(164312, 1, '22-25 38 39 50 51', '0-24', '0-18', '0-9', '0-10');
