-- Zul'Gurub, tester feedback round 3 (Ohgan): Mandokir's raptor fights at double size. Display 215271 is
-- display 15271 with the same textures at a client scale of 2, so the model keeps a scale of 1 and its
-- reach doubles that of 15271 (0.35, 1.5).
DELETE FROM `creature_model_info` WHERE `DisplayID` = 215271;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(215271, 0.7, 3, 0, 0);

UPDATE `creature_template_model` SET `CreatureDisplayID` = 215271, `DisplayScale` = 1
WHERE `CreatureID` IN (14988, 114988, 214988, 314988) AND `Idx` = 0;
