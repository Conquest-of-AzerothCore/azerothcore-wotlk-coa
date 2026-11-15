-- Spirit Glaive (#8914): every rank (806289, 680906, 562715-562719) targets TARGET_UNIT_CONE_ENEMY_24 with a 30 yd
-- radius. Without a spell_cone row the core read the enum suffix as 24 degrees (+/-12), while the client marks the
-- area with its 90 degree cone splat; restore 90, as for Flames of Xoroth, Dreadwake and Dawnbreak. The first-rank
-- row covers the whole chain.
DELETE FROM `spell_cone` WHERE `ID` = 806289;
INSERT INTO `spell_cone` (`ID`, `ConeDegrees`) VALUES (806289, 90);
