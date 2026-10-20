-- Mythical Discharge (823746), Mythical Missiles (823747), Mythical Volley (823697) and Mythical Throw (823699)
-- deal damage "to all enemies in combat" per their tier bonus tooltips (823730, 823710, 823716, 823726) (issue 7238).
DELETE FROM `spell_script_names` WHERE `spell_id` IN (823746, 823747, 823697, 823699)
    AND `ScriptName` = 'spell_ascension_tier_set_mythical_volley';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(823746, 'spell_ascension_tier_set_mythical_volley'),
(823747, 'spell_ascension_tier_set_mythical_volley'),
(823697, 'spell_ascension_tier_set_mythical_volley'),
(823699, 'spell_ascension_tier_set_mythical_volley');
