-- Radiant One gnome female disguise 161780 (spell 256706): display 32697 renders untextured in the client
-- (baked texture CreatureDisplayExtra-21675.blp and its shoulder/mail item assets are in no installed MPQ).
-- Use 6982, the textured gnome female radiation-suit stand-in already used by Radiant Guard 161773 and,
-- since #11937, by Radiant Fanatic 161772.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161780 AND `Idx` = 0;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(161780, 0, 6982, 1, 1);
