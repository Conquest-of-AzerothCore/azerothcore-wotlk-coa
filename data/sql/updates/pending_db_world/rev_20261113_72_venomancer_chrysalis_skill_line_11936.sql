-- Chrysalis (808082) is a Vizier talent (CharacterAdvancement 6324, Tab 92) with no SkillLineAbility row, so no
-- spellbook tab lists it (#11936). The active Vizier talents, such as Blight Antidote (520153, row 23469), sit in
-- SkillLine 499. The client only places a spell into a tab through an existing row, so an unused row is repurposed,
-- as for Shadow Pennant rank 2 (#11505, row 843). Row 844 duplicates row 12780: both map Feign Death (5384) in
-- SkillLine 50 with ClassMask 512 and differ only in MinSkillLineRank (1 against 0), which AcquireMethod 0 ignores,
-- and row 10138 also covers spell 5384, so it keeps its tab. The client's SkillLineAbility.dbc is identical to the
-- server's.
DELETE FROM `skilllineability_dbc` WHERE `ID` = 844;
INSERT INTO `skilllineability_dbc` (`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`,
    `ExcludeClass`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`,
    `TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(844, 499, 808082, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
    `ID` INT UNSIGNED NOT NULL,
    `SkillLine` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 844;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(844, 499);
