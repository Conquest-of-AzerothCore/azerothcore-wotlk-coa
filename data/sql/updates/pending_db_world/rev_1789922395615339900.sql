--
-- Crushing the Earth (#1731): convert half of armor penetration rating into spell power.
DELETE FROM `spell_script_names` WHERE `spell_id` = 300697 AND `ScriptName` = 'aura_ascension_crushing_earth';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (300697, 'aura_ascension_crushing_earth');
