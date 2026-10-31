-- House of Nobles looks rebuilt from realm footage (0MqPfOJqF8w, wJ2j4NOgjRI, pEoiXrErJ6w); review page in the plan.
-- Feet, hands and faces that no clear frame shows are left empty or as placeholders.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (164212, 164213, 164214, 164216, 164217, 164218, 164219);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164212, 0, 50, 1, 1, 0),
(164213, 0, 49, 1, 1, 0),
(164214, 0, 49, 1, 1, 0),
(164216, 0, 50, 1, 1, 0),
(164217, 0, 49, 1, 1, 0),
(164218, 0, 50, 1, 1, 0),
(164219, 0, 49, 1, 1, 0);

DELETE FROM `creature_display_preset` WHERE `entry` IN (164212, 164213, 164214, 164216, 164217, 164218, 164219);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164212, 50, 1, 1, 1, 1, 0, 3, 22, 0, 0, 12490, 0, 0, 9680, 0, 0, 0, 0, 0, 0, 0),
(164213, 49, 1, 0, 1, 19, 19, 16, 4, 5, 0, 23050, 0, 7889, 26503, 22279, 143185, 27613, 0, 23111, 0, 0),
(164214, 49, 1, 0, 1, 3, 0, 5, 16, 0, 0, 0, 0, 0, 28985, 150405, 19443, 1979, 0, 0, 0, 0),
(164216, 50, 1, 1, 1, 7, 8, 21, 13, 0, 0, 0, 0, 0, 23939, 0, 0, 154340, 0, 0, 0, 0),
(164217, 49, 1, 0, 1, 1, 3, 7, 7, 2, 0, 0, 0, 0, 24502, 0, 0, 0, 0, 0, 0, 0),
(164218, 50, 1, 1, 1, 0, 0, 3, 20, 0, 0, 114359, 0, 0, 24503, 0, 0, 0, 0, 0, 0, 0),
(164219, 49, 1, 0, 1, 1, 16, 11, 14, 2, 0, 0, 0, 8550, 6944, 22614, 71277, 2921, 0, 0, 0, 0);
