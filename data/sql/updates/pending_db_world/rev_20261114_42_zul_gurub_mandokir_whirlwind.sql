-- Zul'Gurub: Mandokir's Whirlwind (2118408) hits all within 5 yards (2118409) every second of the spin.
DELETE FROM `spell_script_names` WHERE `spell_id` = 2118408 AND `ScriptName` = 'spell_mandokir_coa_whirlwind';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2118408, 'spell_mandokir_coa_whirlwind');
