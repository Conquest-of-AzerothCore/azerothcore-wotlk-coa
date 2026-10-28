-- [Tinker] Rocket Boots (#8669): 760384 launches a moving caster forward again instead of a run speed surge.
DELETE FROM `spell_script_names` WHERE `spell_id` = 760384 AND `ScriptName` = 'spell_ascension_tinker_rocket_boots';
