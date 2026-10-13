-- Resistant (80023) names $s1 with base points 0 and die sides 0; its amount scales with the creature's level
-- (1 per level), which the client's tooltip cannot show, so it read "increased by 1 to 0". Client text only.
DELETE FROM `coa_client_spell_description` WHERE `ID` = 80023;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(80023, 'Magic Resistance to all elements increased, scaling with the creature\'s level.', 'Magic Resistance to all elements increased, scaling with the creature\'s level.');
