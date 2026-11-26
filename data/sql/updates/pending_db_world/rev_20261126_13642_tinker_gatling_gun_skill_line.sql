-- Gatling Gun (500213) is a Mechsuit ability learned with Build: Mechsuit (801384, row 87469) and placed on the
-- Mechsuit bar alongside Mechsuit: Combustion (801387, row 87470), Mechsuit: Laser Beam (805372, row 23573) and
-- Mechsuit: Activate Jets (801389, row 87471), all of which sit in SkillLine 102 (Mechanics). Gatling Gun had no
-- SkillLineAbility row, so the client filed it under the General spellbook tab (#13642). The client only places a
-- spell into a tab through an existing row, so an unused row is repurposed, as for Chrysalis (#11936, row 844).
-- Row 845 duplicates row 12779: both map Explosive Trap (13813) in SkillLine 50 with ClassMask 512 and differ only
-- in MinSkillLineRank (1 against 0), which AcquireMethod 0 ignores, and row 10131 also covers spell 13813, so it
-- keeps its tab.
DELETE FROM `skilllineability_dbc` WHERE `ID` = 845;
INSERT INTO `skilllineability_dbc` (`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`,
    `ExcludeClass`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`,
    `TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(845, 102, 500213, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
    `ID` INT UNSIGNED NOT NULL,
    `SkillLine` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 845;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(845, 102);
