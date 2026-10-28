DELETE FROM `spell_script_names`
WHERE `spell_id` IN (11520, 19179) AND `ScriptName` = 'spell_ascension_legacy_quest_reward';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(11520, 'spell_ascension_legacy_quest_reward'),
(19179, 'spell_ascension_legacy_quest_reward');
