-- Herald of the Depths (#10429): the transform showed the FacelessOne2 brute, the same model as Dreadnought's
-- void monstrosity, so the two Cultist forms could not be told apart. Display 280071 (#5707) is model 3003
-- (facelessone2 blue, the brute). Ascension's Herald was the masked faceless caster: display 142815 is the CoA
-- caster model (creature\facelessonecaster2\facelessonecaster2_coa.m2, purple skin, DBC scale 0.65), which
-- matches in-game screenshots of the original form. It is player-sized at DisplayScale 1, so no script scale is
-- needed (ScaleBlackEmpire only touches 680556). The custom display has no creature_model_info row, which makes
-- the client fall back to a default model, so it is added here.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 142815, `DisplayScale` = 1 WHERE `CreatureID` = 250042 AND `Idx` = 0;

DELETE FROM `creature_model_info` WHERE `DisplayID` = 142815;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(142815, 1.0, 1.0, 0, 0);
