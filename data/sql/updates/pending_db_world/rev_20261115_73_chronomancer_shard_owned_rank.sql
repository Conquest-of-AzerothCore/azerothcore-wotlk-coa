-- #12287, #12290, #11351: Aeon Rend (583248) re-strikes with the Chromatic Shard rank that hit, and Time Loop
-- (807989) fires the Chromatic Shard rank the Chronomancer owns, instead of the rank 1 record 801292 both name.
DELETE FROM `spell_script_names` WHERE `spell_id` = 583248 AND `ScriptName` = 'aura_ascension_aeon_rend';
DELETE FROM `spell_script_names` WHERE `spell_id` = 807989 AND `ScriptName` = 'spell_ascension_time_loop_shard';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(583248, 'aura_ascension_aeon_rend'),
(807989, 'spell_ascension_time_loop_shard');
