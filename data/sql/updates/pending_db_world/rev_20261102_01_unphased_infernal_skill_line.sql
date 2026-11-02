-- Unphased (803645) has no SkillLineAbility row and falls back to General.
-- Rows 86006 and 86011 both reference Totemic Smash (501056) in SkillLine 41
-- without automatic acquisition. Row 86011 has ExcludeClass 512, while 86006 has
-- no exclusion. Reusing 86011 leaves the non-excluded 86006 mapping intact.
DELETE FROM `skilllineability_dbc` WHERE `ID` = 86011;
INSERT INTO `skilllineability_dbc` (`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(86011, 53, 803645, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
  `ID` INT UNSIGNED NOT NULL,
  `SkillLine` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 86011;
INSERT INTO `coa_client_skill_line_ability` (`ID`,`SkillLine`) VALUES
(86011,53);
