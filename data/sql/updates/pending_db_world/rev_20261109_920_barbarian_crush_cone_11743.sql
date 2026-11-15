-- Crush (#11743): every rank (500915, 501003-501011) targets TARGET_UNIT_CONE_ENEMY_54 with a 7.5 yd radius. Without a
-- spell_cone row the core read the enum suffix as 54 degrees (+/-27), so enemies standing beside the target were
-- skipped. Restore 90, as for Flames of Xoroth, Dreadwake, Dawnbreak, Spirit Glaive and Breath of the North. The
-- first-rank row covers the whole chain.
DELETE FROM `spell_cone` WHERE `ID` = 500915;
INSERT INTO `spell_cone` (`ID`, `ConeDegrees`) VALUES (500915, 90);
