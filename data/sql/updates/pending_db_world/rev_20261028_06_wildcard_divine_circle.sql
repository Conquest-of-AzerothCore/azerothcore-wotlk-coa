-- Grant once per completed Flash Heal/Greater Heal; consume after the empowered Circle heals all targets.
DELETE FROM `spell_script_names` WHERE `spell_id` = 271483 AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
DELETE FROM `spell_script_names` WHERE `spell_id` = 271483 AND `ScriptName` = 'aura_wildcard_divine_circle';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (271483, 'aura_wildcard_divine_circle');
DELETE FROM `spell_script_names` WHERE `spell_id` = -34861 AND `ScriptName` = 'spell_wildcard_divine_circle_consume';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (-34861, 'spell_wildcard_divine_circle_consume');
DELETE FROM `spell_proc` WHERE `SpellId` = 271483;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellPhaseMask`, `Chance`, `DisableEffectsMask`) VALUES
(271483, 87376, 4, 100, 3);
