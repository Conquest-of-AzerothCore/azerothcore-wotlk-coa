-- Gehennas' Flamewaker adds (11661 and its +100000/200000/300000 variants) are the one MC trash type
-- with no coa_boss_flex row at all (rev_20260930_94 omitted it), leaving it on a flat, non-flexed
-- HealthModifier while Gehennas himself scales with raid size -- at 20 players this put the add at
-- about 0.57% of Gehennas' health instead of the Bronzebeard-realm reading of roughly 10%. Flexed here
-- at 10% of Gehennas' own hp_dN (rev_20260930_94), per difficulty, matching the method already used for
-- every other coa_boss_flex row in this encounter (anchored on a sibling boss's own measured shape
-- rather than inventing a new reading).
DELETE FROM `coa_boss_flex` WHERE `entry` = 11661;
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`) VALUES
(11661, 88412, 117882, 177424, 258696, 'Flamewaker: 10% of Gehennas'' own hp_dN (rev_20260930_94), Bronzebeard-realm reading per the user');
