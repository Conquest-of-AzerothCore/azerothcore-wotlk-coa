-- #10823/#11114: Spectral Scythe 500484 "Summons 1 Spectral Scythe for each Reaped Soul active", but its summon
-- effect value is 1, so one scythe appeared whatever the soul count (live logs: 532 summons from 186 casts).
-- The scythe 250305 had no AI that casts Scythe Sweep 500489, its next-swing attack and about 97% of the
-- scythe's live damage events, so it barely hurt anything.
DELETE FROM `spell_script_names` WHERE `spell_id` = 500484 AND `ScriptName` = 'spell_ascension_reaper_spectral_scythe';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500484, 'spell_ascension_reaper_spectral_scythe');
UPDATE `creature_template` SET `ScriptName` = 'npc_ascension_reaper_spectral_scythe' WHERE `entry` = 250305;
