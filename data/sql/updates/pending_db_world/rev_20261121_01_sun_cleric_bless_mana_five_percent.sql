UPDATE `spell_dbc` SET `EffectBasePoints_2` = 4 WHERE `ID` = 805360;
DELETE FROM `coa_client_spell_description` WHERE `ID` = 804247;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(804247, 'Bless yourself and an ally, restoring 5% of their maximum health and 5% of your maximum mana every 10 sec for 5 min.\n\nCan only affect 1 ally at a time.', 'Blessed. Healing the Sun Cleric''s target for 5% of your maximum health and restoring 5% maximum mana to the Sun Cleric every 10 sec.');
