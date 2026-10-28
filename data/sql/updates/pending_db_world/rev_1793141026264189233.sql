-- Manastorm Sunken Temple: suppress Jammal'an's evade/reset while his
-- Hex of Jammal'an charm leaves a solo run with no attackable threat.
DELETE FROM `spell_script_names` WHERE `spell_id` = 12483 AND `ScriptName` = 'spell_manastorm_hex_of_jammalan_charm';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (12483, 'spell_manastorm_hex_of_jammalan_charm');
