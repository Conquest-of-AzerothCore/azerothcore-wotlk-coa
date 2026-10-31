-- Sun Stride (680700) frees the caster from slows, but its snare immunity misses Dazed, whose mechanic is
-- MECHANIC_DAZE (#9835). The Sun Cleric aura lifecycle adds daze immunity for the stride's duration.
DELETE FROM `spell_script_names` WHERE `spell_id` = 680700 AND `ScriptName` = 'aura_ascension_sun_cleric_lifecycle';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (680700, 'aura_ascension_sun_cleric_lifecycle');
