DELETE FROM `creature_template_spell` WHERE `CreatureID` IN (347770, 457771, 457772) AND `Index` IN (0, 1, 3);
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`) VALUES
(347770, 0, 503600, 0),
(347770, 1, 503604, 0),
(347770, 3, 503602, 0),
(457771, 0, 503600, 0),
(457771, 1, 503604, 0),
(457771, 3, 503602, 0),
(457772, 0, 503600, 0),
(457772, 1, 503604, 0),
(457772, 3, 503602, 0);
