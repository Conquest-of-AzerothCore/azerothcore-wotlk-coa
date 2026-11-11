-- Shadow Pennant (CharacterAdvancement 30522, Tab 66) has no SkillLineAbility row for rank 1 (706926) or rank 2
-- (525307), so the client files the talent under General instead of Heretic (#11505). Blade of Yogg-Saron
-- (CharacterAdvancement 33935) shares Tab 66 and sits in SkillLine 90 (Heretic) through row 24171. The client only
-- places a spell into a tab through an existing row, so two unused rows are repurposed, as for Blade of Yogg-Saron
-- rank 2 (#11676, row 842). Row 840 duplicates row 12784 (spell 1495) and row 843 duplicates row 12781 (spell
-- 1499): each pair shares SkillLine 50 and ClassMask 512 and differs only in MinSkillLineRank (1 against 0), which
-- AcquireMethod 0 ignores, and rows 10135 and 10134 also cover those spells, so neither loses its tab.
DELETE FROM `skilllineability_dbc` WHERE `ID` IN (840, 843);
INSERT INTO `skilllineability_dbc` (`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`,
    `ExcludeClass`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`,
    `TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(840, 90, 706926, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
(843, 90, 525307, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
  `ID` INT UNSIGNED NOT NULL,
  `SkillLine` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_skill_line_ability` WHERE `ID` IN (840, 843);
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(840, 90),
(843, 90);
