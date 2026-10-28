-- Icebound Champion: frost skeleton 30300 (CDI scale 2) stands in until the live 561888 row is available.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 30300, `DisplayScale` = 0.5
WHERE `CreatureID` = 500484 AND `Idx` = 0 AND `CreatureDisplayID` = 30810;
