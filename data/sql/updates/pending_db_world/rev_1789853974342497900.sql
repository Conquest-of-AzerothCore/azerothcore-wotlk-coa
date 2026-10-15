-- Complete Hold the Line's incapacitate and knockback immunities.
DELETE FROM `spell_script_names` WHERE `spell_id` = 803830 AND `ScriptName` = 'aura_ascension_guardian_hold_the_line';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES (803830, 'aura_ascension_guardian_hold_the_line');
