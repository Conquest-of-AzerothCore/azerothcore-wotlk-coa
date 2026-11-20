-- Waves of Time (#12342): the cast 801277 (effect 1, cone visual) and its knockback 802600 (cast at cast time by
-- spell_ascension_waves_of_time and again 2 s later by effect 0) both target TARGET_UNIT_CONE_ENEMY_24 with a 10 yd
-- radius. Without a spell_cone row the core read the enum suffix as 24 degrees (+/-12), so enemies standing in
-- front of the Chronomancer but slightly to the side were skipped. Restore 90, as for Flames of Xoroth, Dreadwake,
-- Dawnbreak, Spirit Glaive and Crush. Neither spell has further ranks.
DELETE FROM `spell_cone` WHERE `ID` IN (801277, 802600);
INSERT INTO `spell_cone` (`ID`, `ConeDegrees`) VALUES
(801277, 90),
(802600, 90);
