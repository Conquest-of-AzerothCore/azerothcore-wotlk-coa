-- Zul'Gurub: scripts for the zealots' and Chained Spirits' Ascension dummy spells (Sinister Strike, Blind,
-- Storm Shield and its charges, Resurrection).
DELETE FROM `spell_script_names`
WHERE `spell_id` IN (2118250, 2118252) AND `ScriptName` = 'spell_thekal_coa_zath_strike';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2118250, 'spell_thekal_coa_zath_strike'),
(2118252, 'spell_thekal_coa_zath_strike');

DELETE FROM `spell_script_names` WHERE `spell_id` = 2118261 AND `ScriptName` = 'spell_thekal_coa_storm_shield';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2118261, 'spell_thekal_coa_storm_shield');

DELETE FROM `spell_script_names` WHERE `spell_id` = 2118262 AND `ScriptName` = 'spell_thekal_coa_storm_shield_charge';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2118262, 'spell_thekal_coa_storm_shield_charge');

DELETE FROM `spell_script_names` WHERE `spell_id` = 2118426 AND `ScriptName` = 'spell_mandokir_coa_resurrection';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2118426, 'spell_mandokir_coa_resurrection');
