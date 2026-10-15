-- Pick Lock (804154) was bound to SkillLine 99 ("Pet - Pit Lord"), so learning it never granted Lockpicking (633).
DELETE FROM `skilllineability_dbc` WHERE `ID` = 88835;
INSERT INTO `skilllineability_dbc` (`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(88835, 633, 804154, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);
