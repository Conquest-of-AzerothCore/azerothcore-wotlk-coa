-- Bite Wound (706654) references the hidden server-side passive 532612 in its
-- description ($532612s1). The 3.3.5 client cannot resolve that spell, so the
-- debuff tooltip rendered "equal to 0% of the damage dealt". The server already
-- streams coa_client_spell_description rows to the client (SMSG_PATCH_SPELL),
-- so publish the resolved 50% value here instead of the broken token.
CREATE TABLE IF NOT EXISTS `coa_client_spell_description` (
  `ID` INT UNSIGNED NOT NULL,
  `Description` TEXT NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (706654);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(706654,'Dealing damage to this target with auto attacks now restores health to you equal to 50% of the damage dealt.');
