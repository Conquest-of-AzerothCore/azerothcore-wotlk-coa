INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`, `HealthModifier`, `ManaModifier`, `VerifiedBuild`)
VALUES (50038, 'Scrying Orb', 1, 80, 35, 1, 1, 1, 1, 12340)
ON DUPLICATE KEY UPDATE `name` = 'Scrying Orb', `type` = 1, `HealthModifier` = 1, `ManaModifier` = 1;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 50038 AND `Idx` = 0;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES (50038, 0, 30547, 1, 1, 12340);
