-- The specialization spells swap a free-pick Hero's build, as they do for CoA classes and Wildcard Heroes.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_ascension_freepick_specialization_swap';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(979993, 'spell_ascension_freepick_specialization_swap'),
(979994, 'spell_ascension_freepick_specialization_swap'),
(979995, 'spell_ascension_freepick_specialization_swap'),
(979996, 'spell_ascension_freepick_specialization_swap'),
(979997, 'spell_ascension_freepick_specialization_swap'),
(979986, 'spell_ascension_freepick_specialization_swap'),
(979987, 'spell_ascension_freepick_specialization_swap'),
(979988, 'spell_ascension_freepick_specialization_swap'),
(84874, 'spell_ascension_freepick_specialization_swap'),
(84876, 'spell_ascension_freepick_specialization_swap'),
(84878, 'spell_ascension_freepick_specialization_swap'),
(84880, 'spell_ascension_freepick_specialization_swap'),
(84882, 'spell_ascension_freepick_specialization_swap'),
(84884, 'spell_ascension_freepick_specialization_swap'),
(84886, 'spell_ascension_freepick_specialization_swap'),
(84888, 'spell_ascension_freepick_specialization_swap'),
(84890, 'spell_ascension_freepick_specialization_swap'),
(84892, 'spell_ascension_freepick_specialization_swap'),
(84894, 'spell_ascension_freepick_specialization_swap'),
(84896, 'spell_ascension_freepick_specialization_swap');
