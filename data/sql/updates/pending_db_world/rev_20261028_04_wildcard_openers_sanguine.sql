-- Restore authored opener proc conditions and native bleeding/physical damage scope.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (284354, 286308, 288930)
AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (284354, 286308) AND `ScriptName` = 'aura_wildcard_opener_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(284354, 'aura_wildcard_opener_proc'),
(286308, 'aura_wildcard_opener_proc');
DELETE FROM `spell_script_names` WHERE `spell_id` IN (-8676, -6785) AND `ScriptName` = 'spell_wildcard_opener_consume';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-8676, 'spell_wildcard_opener_consume'),
(-6785, 'spell_wildcard_opener_consume');
DELETE FROM `spell_script_names` WHERE `spell_id` = 288930 AND `ScriptName` = 'aura_wildcard_sanguine_pressure';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (288930, 'aura_wildcard_sanguine_pressure');
DELETE FROM `spell_proc` WHERE `SpellId` IN (284354, 286308, 288930);
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellPhaseMask`, `Chance`, `DisableEffectsMask`) VALUES
(284354, 16, 2, 100, 0),
(286308, 262160, 2, 100, 2),
(288930, 87376, 4, 100, 0);
