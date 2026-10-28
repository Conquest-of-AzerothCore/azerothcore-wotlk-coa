-- Bonesurper Trolls use the model the user checked in game (27498, its gear part of the model) instead of the two mixed models.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 164431;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164431, 0, 27498, 1, 1, 0);
