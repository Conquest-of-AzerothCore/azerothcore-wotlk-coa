-- Eye for an Eye ranks 2-3 need a chain to Rank 1 (9799) so the -9799 script binding reaches every rank.
DELETE FROM `spell_ranks` WHERE `first_spell_id` = 9799;
INSERT INTO `spell_ranks` (`first_spell_id`, `spell_id`, `rank`) VALUES
(9799, 9799, 1),
(9799, 25988, 2),
(9799, 89799, 3);

-- Piercing Shots carries the caster's Perforating Shots armor tear onto the bleeding target.
DELETE FROM `spell_script_names` WHERE `spell_id` = 63468 AND `ScriptName` = 'aura_ascension_perforating_shots';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(63468, 'aura_ascension_perforating_shots');
