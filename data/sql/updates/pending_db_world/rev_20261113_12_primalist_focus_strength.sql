-- Focus (680936 rank 1, 681477 rank 2) raised Intellect and Stamina, which leaves the Strength specialization Primal
-- with nothing to multiply. The core now adds the same percent on Strength as a third effect
-- (AscensionPrimalistTalents.cpp). The client keeps the two-effect spell and its text in Spell.dbc, so the
-- description of both ranks is rewritten here. Focus has no aura text.
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (680936, 681477);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(680936, 'Increases your Strength, Intellect and Stamina by $s1%.', NULL),
(681477, 'Increases your Strength, Intellect and Stamina by $s1%.', NULL);
