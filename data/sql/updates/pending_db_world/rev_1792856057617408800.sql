--
-- Barrier of Light: release the threat redirect on each ally when the area aura ends.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_barrier_of_light';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(805417, 'aura_ascension_barrier_of_light');
