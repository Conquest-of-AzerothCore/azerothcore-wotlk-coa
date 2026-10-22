-- Tentacle of Y'Shaarj (#5319): display 28814 at 0.5 stood about 15 yd tall. 0.15 brings it to about 4.5 yd, the
-- size of the other Old God tentacles (N'Zoth 4.1 yd, C'Thun about 5 yd).
UPDATE `creature_template_model` SET `DisplayScale` = 0.15 WHERE `CreatureID` = 50096 AND `Idx` = 0;
