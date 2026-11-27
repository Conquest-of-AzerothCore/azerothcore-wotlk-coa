-- Stone of Retreat: Hammertoe Digsite lands at the Explorers' League camp instead of the Uldaman cave (#13098)
DELETE FROM `spell_target_position` WHERE `ID` = 1777074 AND `EffectIndex` = 0;
INSERT INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES
(1777074, 0, 0, -6615.76, -3412.74, 279.27, 0, 0);
