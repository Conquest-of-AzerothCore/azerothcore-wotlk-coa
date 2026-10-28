-- Chromaggus as Ascension redesigned him; see boss_chromaggus_coa.cpp.
-- Hourglass Sand (item 19183) already casts Ascension's 2111023; it gets the
-- script that cures bronze unless the bronze dragonflight blessed it.
-- Undo: SET `ScriptName` = 'boss_chromaggus', and delete the spell script row.

UPDATE `creature_template` SET `ScriptName` = 'boss_chromaggus_coa' WHERE `entry` = 14020;

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_chromaggus_coa_hourglass_sand';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (2111023, 'spell_chromaggus_coa_hourglass_sand');
