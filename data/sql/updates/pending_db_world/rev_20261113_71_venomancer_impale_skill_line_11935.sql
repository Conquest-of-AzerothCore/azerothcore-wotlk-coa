-- Impale (560248) is a Fortitude talent (CharacterAdvancement 7169, Tab 78), but SkillLineAbility row 22251 files
-- it under SkillLine 104 (Stalking), so the spellbook does not list it in the Fortitude tab (#11935). Every other
-- active Fortitude talent, such as Molt (805102, row 89239), sits in SkillLine 105. Only the SkillLine changes; the
-- rest of row 22251 is copied from SkillLineAbility.dbc.
DELETE FROM `skilllineability_dbc` WHERE `ID` = 22251;
INSERT INTO `skilllineability_dbc` (`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`,
    `ExcludeClass`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`,
    `TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(22251, 105, 560248, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
    `ID` INT UNSIGNED NOT NULL,
    `SkillLine` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 22251;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(22251, 105);
