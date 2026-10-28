-- Scroll of Retreat: Orgrimmar and Stormwind (#8272): the spells' text read "Returns you to the entrance of the Orgrimmar."
-- They now match their items and the Booty Bay stone.
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (84288, 84289);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(84288, 'Returns you to Orgrimmar in Durotar.', NULL),
(84289, 'Returns you to Stormwind in Elwynn Forest.', NULL);
