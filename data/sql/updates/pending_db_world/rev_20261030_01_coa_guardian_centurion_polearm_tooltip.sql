-- AscensionCompat streams coa_client_spell_description rows to the client as
-- SMSG_PATCH_SPELL; the DLL applies the row to the client Spell record. This
-- corrects the polearm line without a client Spell.dbc patch (#10014).
--
-- Centurion Strike 802738's polearm extra hit is a second 802738 damage event
-- and reuses the spell's swipe visual. Only the wording changes here; the
-- mechanic, damage and sword proc 807967 are unchanged.
CREATE TABLE IF NOT EXISTS `coa_client_spell_description` (
  `ID` INT UNSIGNED NOT NULL,
  `Description` TEXT NOT NULL,
  `ToolTip` TEXT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_spell_description` WHERE `ID` = 802738;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`) VALUES
(802738, 'Stab an enemy, dealing $s3% Weapon Damage plus an additional effect based on your weapon.\r\n\r\n|cFFFFFFFFSword:|r Triggers $807967s1 additional auto attacks.\r\n\r\n|cFFFFFFFFAxe:|r Guaranteed to critically strike for $542238s2% increased damage.\r\n\r\n|cFFFFFFFFMace:|r Ignores $542265s1% of your target\'s Armor.\r\n\r\n|cFFFFFFFFPolearm:|r Swipe the target and enemies behind them an additional time.');
