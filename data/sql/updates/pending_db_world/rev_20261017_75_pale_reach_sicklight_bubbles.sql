-- The "Radioactive Droplets" around Elder Thrymus's summit are Sicklight Bubbles (user, from live): their name and the
-- Sicklight Bubble model.
UPDATE `creature_template` SET `name` = 'Sicklight Bubble' WHERE `entry` = 164587;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 164587;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164587, 0, 142347, 1, 1, 0);
