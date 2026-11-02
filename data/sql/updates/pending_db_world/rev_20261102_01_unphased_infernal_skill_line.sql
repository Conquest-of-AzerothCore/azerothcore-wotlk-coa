-- Unphased (803645) has no SkillLineAbility row and falls back to General.
-- Row 86006 duplicates row 86011 for Totemic Smash (501056): both use SkillLine 41,
-- no race/class mask and no automatic acquisition. Reusing 86006 leaves 86011 intact.
DELETE FROM `skilllineability_dbc` WHERE `ID` = 86006;
INSERT INTO `skilllineability_dbc` (`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(86006, 53, 803645, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
  `ID` INT UNSIGNED NOT NULL,
  `SkillLine` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 86006;
INSERT INTO `coa_client_skill_line_ability` (`ID`,`SkillLine`) VALUES
(86006,53);
