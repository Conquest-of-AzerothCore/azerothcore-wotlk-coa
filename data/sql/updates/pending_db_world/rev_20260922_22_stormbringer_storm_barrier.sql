-- Storm Barrier (707204) modifies Lightning Cage 560032, a hidden companion aura nothing ever applied.
-- The script gives 560032 the lifetime of the cast cage 560030 for players who know Storm Barrier.
DELETE FROM `spell_script_names` WHERE `spell_id` = 560030 AND `ScriptName` = 'aura_ascension_lightning_cage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (560030, 'aura_ascension_lightning_cage');
