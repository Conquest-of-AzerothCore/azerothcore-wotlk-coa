-- Radiant Devotee 161786 (Radiance Town, Coldridge Valley, #11424) renders green: the client lacks the baked NPC
-- textures of 32630 (CreatureDisplayExtra-21646), 47042 (-29140) and 47043 (-29157). Each is replaced by the
-- approved #6747 stand-in of the same race, sex and suit that has its baked texture in the client: 25525 dwarf M
-- diving helmet, 6981 gnome M and 6982 gnome F space helmet. Idx 1 keeps 14656, which renders.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161786 AND `Idx` IN (0, 2, 3);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(161786, 0, 25525, 1, 1),
(161786, 2, 6981, 1, 1),
(161786, 3, 6982, 1, 1);
