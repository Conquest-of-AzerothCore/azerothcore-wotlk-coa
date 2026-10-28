-- Master's Tome Of Specialization (8-20), item 97332, casts spell 92982 (Learning) on use. Spell 92982 is a bare
-- SPELL_EFFECT_LEARN_SPELL with TriggerSpell 0, so it played the learn animation and taught nothing (#4827).
-- Bind a SpellScript that learns the first unknown specialization slot 8-20 instead.
DELETE FROM `spell_script_names` WHERE `spell_id` = 92982 AND `ScriptName` = 'spell_ascension_masters_tome_specialization';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (92982, 'spell_ascension_masters_tome_specialization');
