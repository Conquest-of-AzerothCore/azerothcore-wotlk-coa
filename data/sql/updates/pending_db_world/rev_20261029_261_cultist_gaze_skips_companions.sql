-- Gaze of C'Thun (500110, 502135-502143) jumps past non-combat companions to the next nearby target.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_ascension_cultist_gaze_of_cthun_jump';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500110, 'spell_ascension_cultist_gaze_of_cthun_jump'),
(502135, 'spell_ascension_cultist_gaze_of_cthun_jump'),
(502136, 'spell_ascension_cultist_gaze_of_cthun_jump'),
(502137, 'spell_ascension_cultist_gaze_of_cthun_jump'),
(502138, 'spell_ascension_cultist_gaze_of_cthun_jump'),
(502139, 'spell_ascension_cultist_gaze_of_cthun_jump'),
(502140, 'spell_ascension_cultist_gaze_of_cthun_jump'),
(502141, 'spell_ascension_cultist_gaze_of_cthun_jump'),
(502142, 'spell_ascension_cultist_gaze_of_cthun_jump'),
(502143, 'spell_ascension_cultist_gaze_of_cthun_jump');
