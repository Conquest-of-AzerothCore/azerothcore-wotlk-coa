DELETE FROM `spell_script_names` WHERE `spell_id` IN (680303, 681442) AND `ScriptName` = 'spell_ascension_witch_hunter_greater_knights_edict';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(680303, 'spell_ascension_witch_hunter_greater_knights_edict'),
(681442, 'spell_ascension_witch_hunter_greater_knights_edict');

DELETE FROM `spell_group` WHERE `id` = 1089 AND `spell_id` IN (523485, 523510);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1089, 523485),
(1089, 523510);
