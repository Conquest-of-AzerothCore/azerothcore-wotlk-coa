-- Magma Elemental (5855) used the Nature immunity set (-185); its own Fire Nova (11970) and its Searing Gorge
-- siblings Blazing Elemental (5850) and Inferno Elemental (5852) use the Fire immunity set (-300).
UPDATE `creature_template` SET `CreatureImmunitiesId` = -300 WHERE `entry` = 5855 AND `CreatureImmunitiesId` = -185;
