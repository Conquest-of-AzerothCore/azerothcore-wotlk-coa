-- Blade of Yogg-Saron rank 2 (525078) has no SkillLineAbility row, so the client files it under General
-- while rank 1 (524887, row 24171) sits in SkillLine 90 (Heretic). The client only places a spell into a
-- tab through an existing row, so an unused row is repurposed, as for Annihilation (#7465) and Unphased (#1509).
-- Row 842 duplicates row 12782: both map spell 13809 in SkillLine 50 with ClassMask 512 and differ only in
-- MinSkillLineRank (1 against 0), which AcquireMethod 0 ignores, so 12782 keeps covering spell 13809.
DELETE FROM `skilllineability_dbc` WHERE `ID` = 842;
INSERT INTO `skilllineability_dbc` (`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(842, 90, 525078, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
  `ID` INT UNSIGNED NOT NULL,
  `SkillLine` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 842;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(842, 90);
