-- Grimepit Troggs (164206) and Grime-King Augustus (164207) used the stock creature trogg (606). On the realm they
-- are the troglodyte character body (race 46, display 142832) in armour: the troggs grey with a striped scalp (skin 0,
-- hair style 5), Augustus blue (skin 1). Realm displays 653027/653028 are not in the client, so the look is rebuilt.
-- Evidence: Wo-WScrn-Shot-071226-225122, -224909, -225238; video SGUWwezq2Z0 00:22:12, 00:24:10; 9elvxh9Fct0 00:23:21.
-- Only the body, skins and scalp are close matches. The trogg robe, shoulders, bracers and maul, and Augustus's
-- chest, legs and skull mace are the nearest classic pieces found; his shoulders are the user's pick (Ritualist's
-- Mantle of Desperation, display 146971).
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (164206, 164207);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164206, 0, 142832, 1, 1, 0),
(164207, 0, 142832, 1, 1, 0);

DELETE FROM `creature_display_preset` WHERE `entry` IN (164206, 164207);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164206, 142832, 46, 0, 1, 0, 0, 5, 1, 0, 0, 0, 30475, 0, 20478, 0, 0, 0, 1507, 0, 0, 0),
(164207, 142832, 46, 0, 1, 1, 0, 0, 0, 0, 0, 0, 146971, 0, 11624, 0, 11493, 0, 0, 0, 0, 0);

-- Each trogg rolls its own look: grey, mauve or pale skin, bald or striped scalp, dark plum, brown or red stripes.
-- Blue is left to Augustus; no trogg in the footage is blue.
DELETE FROM `creature_display_preset_variety` WHERE `entry` = 164206;
INSERT INTO `creature_display_preset_variety` (`entry`, `gender`, `skins`, `faces`, `hair_styles`, `hair_colors`, `facial_hairs`) VALUES
(164206, 0, '0 3 5', '0', '0 5', '0 1 5', '0');

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (164206, 164207) AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164206, 1, 10544, 0, 0, 0),
(164207, 1, 1608, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `id` IN (164206, 164207);
