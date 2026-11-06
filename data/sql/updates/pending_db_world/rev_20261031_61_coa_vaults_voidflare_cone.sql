-- Vaults of the Inquisition (map 936): the Deceiver's Voidflare (256927, Heroic/Mythic 256928) is a
-- TARGET_UNIT_CONE_ENEMY_24 cone, which the core makes 24 degrees wide. Its cone shows far wider, so players standing
-- in it were not hit; Ascension's logs have it hit most of a spread group. 60 degrees, as wide as it shows.
DELETE FROM `spell_cone` WHERE `ID` IN (256927, 256928);
INSERT INTO `spell_cone` (`ID`, `ConeDegrees`) VALUES
(256927, 60),
(256928, 60);
