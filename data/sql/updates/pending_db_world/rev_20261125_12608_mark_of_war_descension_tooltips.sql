-- Silver Mark of War (1201002, spell 413116) and Golden Mark of War (1201003, spell 413117)
-- still read "Runes of Ascension" in the client's Spell.dbc (#12608, #12609).
-- Server Spell.dbc already uses "Runes of Descension", but AscensionCompat only streams
-- Spell.dbc descriptions to clients for spells present in coa_client_spell_description.
-- Publish both rows so SMSG_PATCH_SPELL delivers the Descension wording at login.
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (413116, 413117);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(413116, 'Awards 250 Runes of Descension.\n\n4 Silver Marks of War will upgrade into 1 Golden Mark of War.', 'Awards 250 Runes of Descension.'),
(413117, 'Awards 1000 Runes of Descension.', 'Awards 1000 Runes of Descension.');
