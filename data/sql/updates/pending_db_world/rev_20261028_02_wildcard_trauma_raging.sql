-- Card-specific proc controllers; native effects 184 and 196 remain unchanged.
DELETE FROM `spell_script_names` WHERE `spell_id` = 274205 AND `ScriptName` = 'aura_wildcard_trauma_care';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (274205, 'aura_wildcard_trauma_care');
DELETE FROM `spell_script_names` WHERE `spell_id` = 285362 AND `ScriptName` = 'aura_wildcard_raging_momentum';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (285362, 'aura_wildcard_raging_momentum');
DELETE FROM `spell_proc` WHERE `SpellId` IN (274205, 285362);
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellPhaseMask`, `Chance`, `AttributesMask`) VALUES
(274205, 87376, 4, 100, 0),
(285362, 87376, 4, 100, 0);
