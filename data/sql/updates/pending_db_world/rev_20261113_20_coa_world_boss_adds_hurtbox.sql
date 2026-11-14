-- Atal'zul's and Trut-K'hahn's adds copied Azuregos's type flags, boss flag included, so they showed a skull.
UPDATE `creature_template` SET `type_flags` = 0 WHERE `entry` IN (67534, 67535, 67536, 9780030, 9780031);

-- Atal'zul and Zul'rogg had no model info, so their reach was the default and players had to hug them.
DELETE FROM `creature_model_info` WHERE `DisplayID` IN (79329, 79411);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`,
  `VerifiedBuild`) VALUES
(79329, 1.5, 4, 2, 0, 12340),
(79411, 1.5, 4, 2, 0, 12340);

-- Atal'zul hit about twice as hard as intended: his damage is halved, his adds keep theirs.
UPDATE `creature_template` SET `DamageModifier` = 10.2 WHERE `entry` = 67532;
