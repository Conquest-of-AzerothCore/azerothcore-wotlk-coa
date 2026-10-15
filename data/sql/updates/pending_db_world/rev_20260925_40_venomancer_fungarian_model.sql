-- Fungarian (Fungal Assailant 504344) wears Ascension's own fungarian model and is an Elemental, as captured from the
-- live client creature cache (AscensionDB, client captures 2026-06-29 to 2026-09-09), not the purple Fungal Giant.
-- Its model info follows the neighbouring Ascension displays: CreatureModelData 5809 collision width and height.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 49116;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`) VALUES
(49116, 0.611111, 2.03128, 2);
UPDATE `creature_template` SET `type` = 4 WHERE `entry` = 45896;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 49116, `DisplayScale` = 1
WHERE `CreatureID` = 45896 AND `Idx` = 0;
