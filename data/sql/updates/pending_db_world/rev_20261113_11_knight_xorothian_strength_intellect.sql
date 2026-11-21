-- Xorothian Strength (300382 rank 1, 570100 rank 2) now raises Intellect by the same percent as Strength
-- (AscensionXorothContracts.cpp). The client keeps the one-effect spell and its text in Spell.dbc, so its
-- description and the rank 1 aura text are rewritten here.
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (300382, 570100);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(300382, 'Increases your Strength and Intellect by $s1%.', 'Increases Strength and Intellect by ${$w1}%.'),
(570100, 'Increases your Strength and Intellect by $s1%.', NULL);
