--
-- Natural Efficiency (#459): filter its native heal proc to control effects actually applied to the victim.
DELETE FROM `spell_script_names` WHERE `spell_id` = 706167 AND `ScriptName` = 'aura_ascension_natural_efficiency';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(706167, 'aura_ascension_natural_efficiency');
