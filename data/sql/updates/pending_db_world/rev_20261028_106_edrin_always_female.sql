-- Edrin used display 15718, which creature_model_info pairs with 15719, so each spawn picked a man or a woman.
-- She keeps the female version's look (display 15719 / extra 10795) as a preset on display 50, which has no pairing.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 164099;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164099, 0, 50, 1, 1, 0);
DELETE FROM `creature_display_preset` WHERE `entry` = 164099;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164099, 50, 1, 1, 1, 0, 6, 3, 0, 1, 0, 0, 0, 27204, 27205, 19748, 23933, 21833, 0, 0, 0, 0);
