-- Wasp Form (805141) has no SPELL_AURA_FLY; the script applies the helper 805142 that carries it.
DELETE FROM `spell_script_names` WHERE `spell_id` = 805141 AND `ScriptName` = 'aura_ascension_venomancer_wasp_form';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (805141, 'aura_ascension_venomancer_wasp_form');
