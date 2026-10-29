-- Jelena Goret, Sir Kellen Wildash and Brother Caesar looks set in game with the CoA World Edit Look tab.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (164911, 164982, 164985);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164911, 0, 49, 1, 1, 0),
(164982, 0, 50, 1, 1, 0),
(164985, 0, 49, 1, 1, 0);
DELETE FROM `creature_display_preset` WHERE `entry` IN (164911, 164982, 164985);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164911, 49, 1, 0, 1, 8, 3, 3, 3, 4, 0, 0, 22924, 0, 72992, 72988, 72990, 72991, 0, 30486, 142467, 132122),
(164982, 50, 1, 1, 1, 2, 0, 3, 2, 0, 0, 0, 0, 10037, 13122, 13062, 13059, 4947, 0, 0, 0, 0),
(164985, 49, 1, 0, 1, 0, 9, 16, 7, 7, 0, 0, 0, 10615, 28017, 6620, 3135, 1594, 0, 0, 0, 0);
