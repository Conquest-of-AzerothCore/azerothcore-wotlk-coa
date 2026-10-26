-- Remount Master Edward (164592) sells the Scadeald stallions, whose spells 365200-365210 and 365257-365267 apply
-- SPELL_AURA_MOUNTED with creatures 267700-267710 and 379992-380002. None of them had a creature_template row, so the
-- rider got the speed but no mount model. Displays come from CreatureDisplayInfo.dbc: 141899-141909 use model 112838
-- ridinghorsescadeald.m2 and 141910-141920 model 112839 pvpridinghorsescadeald.m2, each with the coat texture named by
-- the spell. Creature cache captures (hertigservices/ascension-data) confirm 141904, 141909 and 141918-141920.
-- CreatureModelData collision of both models gives the model-info radii.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`, `BaseAttackTime`, `RangeAttackTime`) VALUES
(267700, 'Adorned Black Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(267701, 'Adorned Bay Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(267702, 'Adorned Chestnut Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(267703, 'Adorned Grey Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(267704, 'Adorned Palomino Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(267705, 'Adorned Pale Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(267706, 'Adorned Piebald Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(267707, 'Adorned Pinto Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(267708, 'Adorned Dark Bay Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(267709, 'Adorned White Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(267710, 'Adorned Undead Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(379992, 'Midnight Black Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(379993, 'Bay Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(379994, 'Chestnut Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(379996, 'Palomino Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(379997, 'Pale Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(379998, 'Piebald Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(379999, 'Pinto Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(380000, 'Dark Bay Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(380001, 'White Stallion', 1, 1, 35, 1, 12, 2000, 2000),
(380002, 'Undead Stallion', 1, 1, 35, 1, 12, 2000, 2000) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (267700, 267701, 267702, 267703, 267704, 267705, 267706, 267707, 267708, 267709, 267710, 379992, 379993, 379994, 379996, 379997, 379998, 379999, 380000, 380001, 380002);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(267700, 0, 141910, 1, 1),
(267701, 0, 141911, 1, 1),
(267702, 0, 141912, 1, 1),
(267703, 0, 141913, 1, 1),
(267704, 0, 141914, 1, 1),
(267705, 0, 141915, 1, 1),
(267706, 0, 141916, 1, 1),
(267707, 0, 141917, 1, 1),
(267708, 0, 141918, 1, 1),
(267709, 0, 141919, 1, 1),
(267710, 0, 141920, 1, 1),
(379992, 0, 141899, 1, 1),
(379993, 0, 141900, 1, 1),
(379994, 0, 141901, 1, 1),
(379996, 0, 141903, 1, 1),
(379997, 0, 141904, 1, 1),
(379998, 0, 141905, 1, 1),
(379999, 0, 141906, 1, 1),
(380000, 0, 141907, 1, 1),
(380001, 0, 141908, 1, 1),
(380002, 0, 141909, 1, 1);
DELETE FROM `creature_model_info` WHERE `DisplayID` IN (141910, 141911, 141912, 141913, 141914, 141915, 141916, 141917, 141918, 141919, 141920, 141899, 141900, 141901, 141903, 141904, 141905, 141906, 141907, 141908, 141909);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(141899, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141900, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141901, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141903, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141904, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141905, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141906, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141907, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141908, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141909, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141910, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141911, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141912, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141913, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141914, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141915, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141916, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141917, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141918, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141919, 0.6111000180244446, 2.0309998989105225, 2, 0),
(141920, 0.6111000180244446, 2.0309998989105225, 2, 0);
