-- Justice (572848): the DBC text shows one figure ($524857m2 = 6) for both hands, while the server deals
-- 157 (main hand, 572850) and 105 (off hand, 572045) as flat damage plus the 20% spell power term (owner O-33 / O-38).
DELETE FROM `coa_client_spell_description` WHERE `ID` = 572848;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(572848, 'Spin and strike with both weapons dealing $524857s1% Weapon Damage to up to $i enemies within $a1 yds.\r\n\r\nYour main-hand strike deals an additional ${$572850m2+$spfi*0.2} Physical damage and your off-hand strike deals an additional ${$572045m2+$spfi*0.2} Fire damage.', NULL);
