-- Binds spell_ascension_wildcard_shadowfall_tick (AscensionWildcardShadowfall.cpp) to the Shadowfall 1s tick
-- spell, whose SPELL_EFFECT_DUMMY effect is otherwise a native no-op.
DELETE FROM `spell_script_names` WHERE `spell_id` = 284652 AND `ScriptName` = 'spell_ascension_wildcard_shadowfall_tick';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(284652, 'spell_ascension_wildcard_shadowfall_tick');
