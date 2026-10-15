DELETE FROM `skilllineability_dbc` WHERE `ID` IN (22848, 23467);
INSERT INTO `skilllineability_dbc` (
    `ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`,
    `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`,
    `CharacterPoints_1`, `CharacterPoints_2`
) VALUES
(22848, 633, 804662, 0, 8388608, 0, 0, 1, 0, 0, 0, 0, 0, 0),
(23467, 633, 570122, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);
