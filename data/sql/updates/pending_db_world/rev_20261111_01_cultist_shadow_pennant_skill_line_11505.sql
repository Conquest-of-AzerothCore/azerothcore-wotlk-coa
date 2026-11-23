-- Shadow Pennant rank 2 (525307) has no SkillLineAbility row, so the client files it under General instead of
-- Heretic (#11505). The talent (CharacterAdvancement 30522) shares Tab 66 with Blade of Yogg-Saron
-- (CharacterAdvancement 33935), whose rank 1 sits in SkillLine 90 (Heretic) through row 24171. Rank 1 (706926)
-- carries SPELL_ATTR0_DO_NOT_DISPLAY in the client's Spell.dbc, so no spellbook tab ever lists it. The client only
-- places a spell into a tab through an existing row, so an unused row is repurposed, as for Blade of Yogg-Saron
-- rank 2 (#11676, row 842). Row 843 duplicates row 12781: both map spell 1499 in SkillLine 50 with ClassMask 512
-- and differ only in MinSkillLineRank (1 against 0), which AcquireMethod 0 ignores, and row 10134 also covers
-- spell 1499, so it keeps its tab.
DELETE FROM `skilllineability_dbc` WHERE `ID` = 843;
INSERT INTO `skilllineability_dbc` (`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`,
    `ExcludeClass`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`,
    `TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(843, 90, 525307, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
    `ID` INT UNSIGNED NOT NULL,
    `SkillLine` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 843;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(843, 90);
