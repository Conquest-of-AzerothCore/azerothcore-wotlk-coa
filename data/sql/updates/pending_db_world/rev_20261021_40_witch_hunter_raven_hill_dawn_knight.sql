-- Secret of Raven Hill (#6799): Surging Blade, Dark Peril and Vampiric Rage had no Witch Hunter ability script, so
-- casting one never consumed Dawn Knight (681390) and every Raven Hill variant stayed free while it lasted.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (681788, 685020, 686020) AND `ScriptName` = 'spell_ascension_witch_hunter_ability';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(681788, 'spell_ascension_witch_hunter_ability'),
(685020, 'spell_ascension_witch_hunter_ability'),
(686020, 'spell_ascension_witch_hunter_ability');
