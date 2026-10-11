-- Mechagon Peacekeeper (1245284): the mount wrapper never ran its script, so casting it mounted nothing.
DELETE FROM `spell_script_names` WHERE `spell_id` = 1245284 AND `ScriptName` = 'spell_ascension_local_mount';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1245284, 'spell_ascension_local_mount');
