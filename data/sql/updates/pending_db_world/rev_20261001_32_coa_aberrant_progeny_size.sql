-- Aberrant Progeny 161757 (The True Heir of the Cains), from CoA footage: it attacks on sight (faction 14, as the
-- estate's other undead hunters; it was 7, passive) and stands roughly as tall as the player, about 0.6 of the size
-- it drew (display 76125 has no scale of its own, 1.0) (INFERRED from the footage).
UPDATE `creature_template` SET `faction` = 14 WHERE `entry` = 161757;
UPDATE `creature_template_model` SET `DisplayScale` = 0.6 WHERE `CreatureID` = 161757 AND `Idx` = 0;
