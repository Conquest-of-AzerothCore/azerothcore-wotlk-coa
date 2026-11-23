-- Thrown (176) SkillRaceClassInfo 233 also allows Guardian (class 18); mask 2568 | 131072
DELETE FROM `skillraceclassinfo_dbc` WHERE `ID` = 233;
INSERT INTO `skillraceclassinfo_dbc` (`ID`, `SkillID`, `RaceMask`, `ClassMask`, `Flags`, `MinLevel`, `SkillTierID`, `SkillCostIndex`) VALUES
(233, 176, -1, 133640, 128, 0, 0, 0);
