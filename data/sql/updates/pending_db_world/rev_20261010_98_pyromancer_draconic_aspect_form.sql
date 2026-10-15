-- Draconic Aspect (802117) shows the dracthyr model while active. The proc
-- script stays registered; scripts are a multimap per spell so both run.
DELETE FROM `spell_script_names` WHERE `spell_id` = 802117 AND `ScriptName` = 'aura_ascension_pyromancer_draconic_form';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (802117, 'aura_ascension_pyromancer_draconic_form');
