-- Fired Up! (704823) is granted by CharacterAdvancement entry 33877 in the
-- Incineration tab (Tab 62), but its SkillLineAbility.dbc row 90281 points at
-- SkillLine 86 (Flameweaving), so the client files the spell under the wrong
-- spellbook tab. Publish the row with SkillLine 85 (Incineration), which
-- AscensionCompat streams as SMSG_PATCH_SKILL_LINE_ABILITY at login.
-- The same migration pins the buff's critical strike line: the DBC text carries
-- it as $s3%, which does not render on the buff, while Effect[2] grants a fixed
-- 29 (displayed as 30%) that nothing rescales, so the override states 30%
-- outright and leaves the working $h% and $d parts untouched.
CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
  `ID` INT UNSIGNED NOT NULL,
  `SkillLine` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 90281;
INSERT INTO `coa_client_skill_line_ability` (`ID`,`SkillLine`) VALUES
(90281,85);

CREATE TABLE IF NOT EXISTS `coa_client_spell_description` (
  `ID` INT UNSIGNED NOT NULL,
  `Description` TEXT NOT NULL,
  `ToolTip` TEXT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_spell_description` WHERE `ID` = 704823;
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(704823,'Your |cffff7f7fEmber|r spenders are now instant and have a $h% chance to refund their cost and increases your chance to critically strike by 30% for $d.');
