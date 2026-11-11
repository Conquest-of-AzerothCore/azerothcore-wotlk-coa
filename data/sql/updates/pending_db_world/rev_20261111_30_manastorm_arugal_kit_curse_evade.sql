-- Manastorm Shadowfang Keep: Archmage Arugal's Ascension kit also casts Curse of
-- Arugal (2102679), a second charm beside Arugal's Curse (7621). Bind it to the same
-- evade suppression so the charm does not reset the fight.
DELETE FROM `spell_script_names` WHERE `spell_id` = 2102679 AND `ScriptName` = 'spell_manastorm_arugals_curse';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (2102679, 'spell_manastorm_arugals_curse');
