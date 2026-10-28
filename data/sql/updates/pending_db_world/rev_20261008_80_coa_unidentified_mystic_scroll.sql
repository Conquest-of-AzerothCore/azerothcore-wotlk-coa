-- Unidentified Mystic Scroll (97866): using it reveals a random Mystic Scroll (spell_ascension_unidentified_mystic_scroll).
DELETE FROM `spell_script_names` WHERE `spell_id` = 93228 AND `ScriptName` = 'spell_ascension_unidentified_mystic_scroll';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(93228, 'spell_ascension_unidentified_mystic_scroll');
