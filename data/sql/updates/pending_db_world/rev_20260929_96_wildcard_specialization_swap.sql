-- Character Advancement lists 20 specializations; the client casts the spec's swap spell (effect 162 with the spec
-- index) to activate one (SPEC_SWAP_SPELLS in FrameXML/Constants.lua). For a Wildcard Hero it swaps the whole
-- rolled build with its scrolls, skill card slots and action bars.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_wildcard_specialization_swap';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(979993, 'spell_wildcard_specialization_swap'),
(979994, 'spell_wildcard_specialization_swap'),
(979995, 'spell_wildcard_specialization_swap'),
(979996, 'spell_wildcard_specialization_swap'),
(979997, 'spell_wildcard_specialization_swap'),
(979986, 'spell_wildcard_specialization_swap'),
(979987, 'spell_wildcard_specialization_swap'),
(979988, 'spell_wildcard_specialization_swap'),
(84874, 'spell_wildcard_specialization_swap'),
(84876, 'spell_wildcard_specialization_swap'),
(84878, 'spell_wildcard_specialization_swap'),
(84880, 'spell_wildcard_specialization_swap'),
(84882, 'spell_wildcard_specialization_swap'),
(84884, 'spell_wildcard_specialization_swap'),
(84886, 'spell_wildcard_specialization_swap'),
(84888, 'spell_wildcard_specialization_swap'),
(84890, 'spell_wildcard_specialization_swap'),
(84892, 'spell_wildcard_specialization_swap'),
(84894, 'spell_wildcard_specialization_swap'),
(84896, 'spell_wildcard_specialization_swap');
