-- Invigorating Winds (705661) promises silence and interrupt immunity, but its two effects are a no-op
-- damage-taken aura and SPELL_AURA_REDUCE_PUSHBACK; the script carries the immunity for the aura's lifetime.
DELETE FROM `spell_script_names` WHERE `spell_id` = 705661 AND `ScriptName` = 'aura_ascension_invigorating_winds';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (705661, 'aura_ascension_invigorating_winds');
