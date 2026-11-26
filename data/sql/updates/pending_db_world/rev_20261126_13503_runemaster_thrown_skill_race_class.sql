-- Thrown (176) SkillRaceClassInfo 233 allows Guardian (18), Reaper (30), and Runemaster (32)
-- ClassMask: 133640 | 536870912 | 2147483648 = 2684488200 (0xA0020A08) = -1610479096 (int32)
DELETE FROM `skillraceclassinfo_dbc` WHERE `ID` = 233;
INSERT INTO `skillraceclassinfo_dbc` (`ID`, `SkillID`, `RaceMask`, `ClassMask`, `Flags`, `MinLevel`, `SkillTierID`, `SkillCostIndex`) VALUES
(233, 176, -1, -1610479096, 128, 0, 0, 0);
