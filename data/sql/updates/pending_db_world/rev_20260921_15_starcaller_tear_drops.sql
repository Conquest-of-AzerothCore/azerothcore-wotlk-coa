-- Tear Drops (560896) needs the Aspect of the Goddess heal helper 801401 to keep its healing-taken aura.
-- Spell.dbc 801401 effect 1 is SPELL_AURA_MOD_HEALING_RECEIVED (283), base points -1 (a base of 0), no
-- duration record. Tear Drops carries three flat spell mods on 801401 (mask word2 0x8000000): EFFECT2 +1,
-- MAX_AURA_STACKS +9 (StackAmount 1 -> 10) and DURATION +10000 ms. AscensionStarcallerContracts.cpp used to
-- clear that effect, so no aura existed for the mods to change. The effect is now kept and
-- spell_ascension_starcaller_ability prevents it (PreventHitDefaultEffect) unless the caster has 560896.
DELETE FROM `spell_script_names` WHERE `spell_id` = 801401 AND `ScriptName` = 'spell_ascension_starcaller_ability';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (801401, 'spell_ascension_starcaller_ability');
