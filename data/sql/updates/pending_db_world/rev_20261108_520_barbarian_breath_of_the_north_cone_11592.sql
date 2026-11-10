-- Breath of the North (#11592): every rank (800838, 802386-802392) targets TARGET_UNIT_CONE_ENEMY_24 with a 12 yd
-- radius. Without a spell_cone row the core read the enum suffix as 24 degrees (+/-12), so an enemy a couple of yards
-- off the facing line was skipped. Restore 90, as for Flames of Xoroth, Dreadwake, Dawnbreak and Spirit Glaive. The
-- first-rank row covers the whole chain.
DELETE FROM `spell_cone` WHERE `ID` = 800838;
INSERT INTO `spell_cone` (`ID`, `ConeDegrees`) VALUES (800838, 90);
