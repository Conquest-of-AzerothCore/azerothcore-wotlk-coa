-- Roll the Bones (760080) applies one of its eight enhancements (760082-760089), replacing the previous one.
DELETE FROM `spell_script_names` WHERE `spell_id` = 760080 AND `ScriptName` = 'spell_ascension_roll_the_bones';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(760080, 'spell_ascension_roll_the_bones');
