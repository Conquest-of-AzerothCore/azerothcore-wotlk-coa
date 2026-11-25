DELETE FROM `spell_script_names`
WHERE `spell_id` IN (570042, 801514, 504022, 801411, 505229)
  AND `ScriptName` = 'spell_ascension_necromancer_command_area';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(570042, 'spell_ascension_necromancer_command_area'),
(801514, 'spell_ascension_necromancer_command_area'),
(504022, 'spell_ascension_necromancer_command_area'),
(801411, 'spell_ascension_necromancer_command_area'),
(505229, 'spell_ascension_necromancer_command_area');
