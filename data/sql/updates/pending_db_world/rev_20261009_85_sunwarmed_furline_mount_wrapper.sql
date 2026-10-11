-- Sunwarmed Furline (9931327): the mount wrapper never ran its script, so casting it mounted nothing.
DELETE FROM `spell_script_names` WHERE `spell_id` = 9931327 AND `ScriptName` = 'spell_ascension_local_mount';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(9931327, 'spell_ascension_local_mount');
