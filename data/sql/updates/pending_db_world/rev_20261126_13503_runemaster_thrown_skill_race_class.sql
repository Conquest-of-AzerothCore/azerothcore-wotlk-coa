-- Thrown (176) SkillRaceClassInfo 233 also allows Runemaster (class 32); mask 133640 | 2147483648 = -2147350008
DELETE FROM `skillraceclassinfo_dbc` WHERE `ID` = 233;
INSERT INTO `skillraceclassinfo_dbc` (`ID`, `SkillID`, `RaceMask`, `ClassMask`, `Flags`, `MinLevel`, `SkillTierID`, `SkillCostIndex`) VALUES
(233, 176, -1, -2147350008, 128, 0, 0, 0);
