-- Relentless Reflexes (276302): finishing moves grant Relentless Reflexes (276306) without refreshing its duration.
-- The passive carried no proc flags or script, so it granted nothing. Same finish-phase controller as Trauma Care.
DELETE FROM `spell_script_names` WHERE `spell_id` = 276302 AND `ScriptName` = 'aura_wildcard_relentless_reflexes';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (276302, 'aura_wildcard_relentless_reflexes');
DELETE FROM `spell_proc` WHERE `SpellId` = 276302;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellPhaseMask`, `Chance`, `AttributesMask`) VALUES
(276302, 87376, 4, 100, 0);
