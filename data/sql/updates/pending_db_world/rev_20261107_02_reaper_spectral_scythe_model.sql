-- #10823: the Spectral Scythe 250305 showed display 25398 (a runebladed sword), chosen when the deployed
-- CreatureDisplayInfo.dbc was thought to lack a scythe model. Display 427586 exists in the client and server
-- CreatureDisplayInfo, is the creature that Show Weapons Only 707188 transforms the scythe into, and is the live
-- modelid1 of 250305 (AscensionDB creaturecache captures, 2026-08-06 to 2026-09-08; Project Descension
-- coa_creature_models.sql). Approved by the maintainer on 2026-11-07.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 250305;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(250305, 0, 427586, 1, 1);
