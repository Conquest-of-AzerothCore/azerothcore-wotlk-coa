-- Hallow Wind Priests, Paladins and Crusaders wore placeholder looks from the first import (a plain green robe, and
-- the Graysky Guard outfit). Rebuilt from the live realm.
-- Priest (164189): the robe Father Amrod wears, without his shoulders (Wo-WScrn-Shot-071226-224503; video 9elvxh9Fct0
-- 00:04:16), with the same set's belt, boots and gloves.
-- Paladin (164190): bare-headed in the gold Alliance plate chest with a blue collar (video 9elvxh9Fct0 00:13:44,
-- 00:04:17, 00:30:10); shoulders, legs, boots and gloves are set pieces not confirmed by the footage. Men and women,
-- as the realm's two models. They carry the Hallow Wind Initiates' longsword; the footage shows a one-handed sword
-- at the hip but not which.
-- Crusader (164209): the dead beside Crusader Diallos, in white and gold plate with no tabard or cloak
-- (Wo-WScrn-Shot-071226-225025, -225037, -224909); the set is the one Diallos wears, not confirmed piece by piece.
DELETE FROM `creature_display_preset` WHERE `entry` IN (164189, 164190, 164209);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164189, 49, 1, 0, 1, 0, 0, 11, 1, 6, 0, 0, 0, 0, 135966, 136027, 0, 135967, 0, 135963, 0, 0),
(164189, 50, 1, 1, 1, 0, 0, 14, 3, 0, 0, 0, 0, 0, 135966, 136027, 0, 135967, 0, 135963, 0, 0),
(164190, 49, 1, 0, 1, 8, 4, 3, 9, 4, 0, 0, 37324, 0, 24528, 0, 21021, 21064, 0, 24531, 0, 0),
(164190, 50, 1, 1, 1, 5, 4, 5, 3, 1, 0, 0, 37324, 0, 24528, 0, 21021, 21064, 0, 24531, 0, 0),
(164209, 49, 1, 0, 1, 8, 4, 3, 0, 4, 0, 0, 144805, 0, 144802, 144800, 144804, 144801, 144806, 144803, 0, 0),
(164209, 50, 1, 1, 1, 5, 4, 5, 3, 1, 0, 0, 144805, 0, 144802, 144800, 144804, 144801, 144806, 144803, 0, 0);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (164190, 164209) AND `Idx` = 1;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164190, 1, 50, 1, 1, 0),
(164209, 1, 50, 1, 1, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164190 AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164190, 1, 869, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `id` = 164190;
