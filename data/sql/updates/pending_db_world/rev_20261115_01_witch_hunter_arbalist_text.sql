-- Arbalist (520851): owner ruling O-2 (2026-11-15), the passive grants ranged attack power only.
DELETE FROM `coa_client_spell_description` WHERE `ID` = 520851;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(520851, '|cFF66DDFFLevel 30 Passive|r\r\nIncreases your ranged attack power by $s1% of your Intellect.', '');
