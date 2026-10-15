-- Venoshroom (Mushroom 506018) wears Ascension's hostile wild mushroom, display 128263
-- (spells\Druid_Wild_Mushroom_03Hostile.M2), as captured from the live client creature cache
-- (AscensionDB, client captures 2026-08-06 to 2026-09-10), not the invisible stalker 26981.
-- Its model info follows the stalker's row it replaces, and it keeps its 0.55 display scale.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 128263;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`) VALUES
(128263, 0.5, 1, 2);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 128263, `DisplayScale` = 0.55
WHERE `CreatureID` = 506018 AND `Idx` = 0;
