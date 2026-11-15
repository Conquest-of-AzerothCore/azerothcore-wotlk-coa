-- Stormwind Royal Guards (1756) were all men: the template had only the male guard model. The female guard model
-- (5446, the one Stormwind City Guards use) is added so the keep's guards are a mix.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 1756 AND `Idx` = 1;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(1756, 1, 5446, 1, 1, 0);
