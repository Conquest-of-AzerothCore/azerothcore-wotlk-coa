START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 271165 AND `ScriptName` = 'aura_wildcard_effective_heal';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (271165, 'aura_wildcard_effective_heal');
DELETE FROM `spell_script_names` WHERE `spell_id` = 34123 AND `ScriptName` = 'aura_wildcard_tree_healing';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (34123, 'aura_wildcard_tree_healing');
COMMIT;
