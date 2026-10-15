-- The Radioactive Droplets around Elder Thrymus's summit look like the Sicklight Bubble (its Ascension bubble model).
DELETE FROM `creature_template_model` WHERE `CreatureID` = 164587;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164587, 0, 142347, 1, 1, 0);
