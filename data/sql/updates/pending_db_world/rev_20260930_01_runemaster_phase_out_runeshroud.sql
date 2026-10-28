-- Phase Out (500671, #5772) triggers 560269. That record's effect 2 names Runeshroud (500288) but only
-- shifts its cooldown by 1 ms, so the aura never lands. The script applies Runeshroud instead.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 560269 AND `ScriptName` = 'spell_ascension_runemaster_phase_out';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(560269, 'spell_ascension_runemaster_phase_out');
