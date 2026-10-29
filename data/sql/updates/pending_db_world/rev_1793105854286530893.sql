-- Binds spell_ascension_wildcard_frost_spree (AscensionWildcardFrostSpree.cpp, SpellScript+AuraScript pair) to
-- Frost Spree, whose SPELL_EFFECT_DUMMY/SPELL_AURA_PERIODIC_DUMMY effects are otherwise native no-ops.
DELETE FROM `spell_script_names` WHERE `spell_id` = 913453 AND `ScriptName` = 'spell_ascension_wildcard_frost_spree';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(913453, 'spell_ascension_wildcard_frost_spree');
