-- Soulstone Lure (557911, #7501) uses the live server's crystal (display 407282, Dragon Soul's Hagara crystal) instead of
-- a shrunken ziggurat crystal. The model's lowest point is 2.36 yd below its origin, so it hovers 2.4 yd to stand on the
-- ground.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 407282;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(407282, 2.44, 1.5, 2, 0);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 557911;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(557911, 0, 407282, 1, 1, 0);
UPDATE `creature_template` SET `HoverHeight` = 2.4 WHERE `entry` = 557911;
