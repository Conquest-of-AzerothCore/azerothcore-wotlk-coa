-- Thrown (176) SkillRaceClassInfo 233 allows Runemaster (class 32, bit 31 = 2147483648) without dropping other classes
-- DBC base row 233 ClassMask = 2568 (0x00000A08); with Runemaster bit 31 = 2568 - 2147483648 = -2147481080 (int32)
INSERT IGNORE INTO `skillraceclassinfo_dbc` (`ID`, `SkillID`, `RaceMask`, `ClassMask`, `Flags`, `MinLevel`, `SkillTierID`, `SkillCostIndex`) VALUES
(233, 176, -1, -2147481080, 128, 0, 0, 0);
UPDATE `skillraceclassinfo_dbc` SET `ClassMask` = IF((`ClassMask` & 2147483648) = 0, `ClassMask` - 2147483648, `ClassMask`) WHERE `ID` = 233;
