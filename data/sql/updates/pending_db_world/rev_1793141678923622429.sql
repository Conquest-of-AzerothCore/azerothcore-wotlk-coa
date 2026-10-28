-- Manastorm Shadowfang Keep: suppress Archmage Arugal's evade/reset while
-- Arugal's Curse leaves a solo run with no attackable threat.
DELETE FROM `spell_script_names` WHERE `spell_id` = 7621 AND `ScriptName` = 'spell_manastorm_arugals_curse';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (7621, 'spell_manastorm_arugals_curse');
