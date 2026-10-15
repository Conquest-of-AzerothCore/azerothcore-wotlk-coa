-- Mercenary Mode (#4512): cast checks for the mercenary ability and the loyalty spells that end it.
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_ascension_mercenary', 'spell_ascension_mercenary_loyalty');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(9930874, 'spell_ascension_mercenary'),
(101100, 'spell_ascension_mercenary_loyalty'),
(101101, 'spell_ascension_mercenary_loyalty');
