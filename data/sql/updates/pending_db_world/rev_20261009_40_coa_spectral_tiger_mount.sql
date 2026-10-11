DELETE FROM `spell_script_names`
WHERE `spell_id` = 42777 AND `ScriptName` = 'spell_ascension_local_mount';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(42777, 'spell_ascension_local_mount');
