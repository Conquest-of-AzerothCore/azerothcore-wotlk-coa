-- Rearmament (805738): its cast script resets the Traps, which its unhandled effect 1 was meant to do.
DELETE FROM `spell_script_names` WHERE `spell_id` = 805738 AND `ScriptName` = 'spell_ascension_witch_hunter_ability';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (805738, 'spell_ascension_witch_hunter_ability');
