-- Periodic healing and Elemental Mastery/Clearcasting use native lifecycle after reviewed metadata conversion.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (283964, 283696)
AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
DELETE FROM `spell_script_names` WHERE `spell_id` = 283964 AND `ScriptName` = 'aura_wildcard_flow_of_life';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (283964, 'aura_wildcard_flow_of_life');
DELETE FROM `spell_script_names` WHERE `spell_id` = 283696 AND `ScriptName` = 'aura_wildcard_avatar_lightning';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (283696, 'aura_wildcard_avatar_lightning');
DELETE FROM `spell_script_names` WHERE `spell_id` = 16246 AND `ScriptName` = 'aura_wildcard_elemental_clearcasting';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (16246, 'aura_wildcard_elemental_clearcasting');
DELETE FROM `spell_proc` WHERE `SpellId` IN (283964, 283696, 16164, 16246);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`,
`AttributesMask`, `Chance`, `Cooldown`, `Charges`, `DisableEffectsMask`) VALUES
(283964, 0, 278528, 2, 2, 0, 2, 100, 0, 0, 0),
(283696, 0, 87376, 0, 4, 0, 0, 100, 0, 0, 0),
(16164, 28, 69904, 1, 2, 2, 0, 100, 500, 0, 0),
(16246, 126, 87376, 0, 4, 0, 0, 100, 0, 2, 6);
