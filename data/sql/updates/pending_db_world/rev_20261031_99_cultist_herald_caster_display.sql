-- Herald of the Depths (#10429): the transform showed the FacelessOne2 brute, the same model as Dreadnought's
-- void monstrosity, so the two Cultist forms could not be told apart. Display 280071 (#5707) is model 3003
-- (facelessone2 blue, the brute). Ascension's Herald was the masked faceless caster: display 280072 is
-- creature\facelessonecaster2\facelessonecaster2.m2 with the purple skin at DBC scale 0.65, confirmed in game
-- against screenshots of the original form. Transforms ignore DisplayScale, so its size comes from the DBC
-- scale alone (ScaleBlackEmpire only touches 680556). The custom display has no creature_model_info row, which
-- makes the client fall back to a default model, so it is added here.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 280072, `DisplayScale` = 1 WHERE `CreatureID` = 250042 AND `Idx` = 0;

DELETE FROM `creature_model_info` WHERE `DisplayID` = 280072;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(280072, 1.0, 1.0, 0, 0);
