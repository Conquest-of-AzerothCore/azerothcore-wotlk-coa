-- Captain Greenskin (647): the vanilla Poisoned Harpoon keeps its cast bar and its effects are replaced by the Ascension Poisoned Harpoon
DELETE FROM `smart_scripts` WHERE `entryorguid` = 64700 AND `source_type` = 9;
UPDATE `smart_scripts` SET `action_type` = 11, `action_param1` = 5208, `action_param2` = 0, `action_param3` = 0, `target_type` = 5 WHERE `entryorguid` = 647 AND `source_type` = 0 AND `id` = 1;

DELETE FROM `spell_script_names` WHERE `spell_id` = 5208 AND `ScriptName` = 'spell_ascension_greenskin_poisoned_harpoon';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(5208, 'spell_ascension_greenskin_poisoned_harpoon');
