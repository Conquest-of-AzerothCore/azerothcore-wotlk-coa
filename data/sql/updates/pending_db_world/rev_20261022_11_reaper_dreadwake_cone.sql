-- Dreadwake (#5353): without a spell_cone row its TARGET_UNIT_CONE_ENEMY_24 cone was read as 24 degrees; restore 90.
DELETE FROM `spell_cone` WHERE `ID` = 803992;
INSERT INTO `spell_cone` (`ID`, `ConeDegrees`) VALUES (803992, 90);
