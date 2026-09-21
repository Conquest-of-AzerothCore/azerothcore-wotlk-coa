-- The SQL-backed Manastorm module owns baseline tool validation and charges.
-- Retire the donor potion binding without touching unrelated spell scripts.
DELETE FROM `spell_script_names` WHERE `spell_id` = 254440 AND `ScriptName` = 'spell_ascension_manastorm_potion';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (254440, 93309, 93311) AND `ScriptName` = 'spell_manastorm_baseline_tool';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(254440, 'spell_manastorm_baseline_tool'),
(93309, 'spell_manastorm_baseline_tool'),
(93311, 'spell_manastorm_baseline_tool');
