-- Thrown (176) SkillRaceClassInfo 233 also allows Reaper (class 30, bit 536870912); base DBC mask 2568 | 536870912 = 536873480
INSERT IGNORE INTO `skillraceclassinfo_dbc` (`ID`, `SkillID`, `RaceMask`, `ClassMask`, `Flags`, `MinLevel`, `SkillTierID`, `SkillCostIndex`) VALUES
(233, 176, -1, 536873480, 128, 0, 0, 0);
UPDATE `skillraceclassinfo_dbc` SET `ClassMask` = IF((`ClassMask` & 536870912) = 0, `ClassMask` + 536870912, `ClassMask`) WHERE `ID` = 233;
