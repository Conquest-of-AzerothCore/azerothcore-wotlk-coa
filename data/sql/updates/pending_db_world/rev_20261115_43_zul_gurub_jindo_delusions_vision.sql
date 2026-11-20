-- Zul'Gurub: Jin'do's Shade detection (24306) ends when the Delusions vision (2118511) ends.
DELETE FROM `spell_script_names` WHERE `spell_id` = 2118511 AND `ScriptName` = 'spell_jindo_coa_delusions_vision';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2118511, 'spell_jindo_coa_delusions_vision');
