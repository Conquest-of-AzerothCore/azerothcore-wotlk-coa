-- Grey Stallion 365260 (item 560260, Pale Reach quest 175007) applies SPELL_AURA_MOUNTED with creature 379995, which had
-- no creature_template row, so the rider got the speed but no mount model. Display 141902 is the creature cache
-- capture (hertigservices/ascension-data, 2026-09-04) and exists in CreatureDisplayInfo.dbc with model 112838,
-- ridinghorsescadeald.m2, whose CreatureModelData collision gives the model-info radii.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`, `BaseAttackTime`, `RangeAttackTime`) VALUES
(379995, 'Grey Stallion', 1, 1, 35, 1, 12, 2000, 2000) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 379995;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(379995, 0, 141902, 1, 1);
DELETE FROM `creature_model_info` WHERE `DisplayID` = 141902;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(141902, 0.6111000180244446, 2.0309998989105225, 2, 0);
