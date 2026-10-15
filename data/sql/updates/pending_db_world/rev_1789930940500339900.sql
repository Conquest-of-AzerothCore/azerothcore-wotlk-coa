--
-- Infused With Power (#1901): effective Hand/Hammer healing grants the native raid critical buff.
DELETE FROM `spell_proc` WHERE `SpellId` = 503718;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(503718, 0, 37, 0, 8, 1048576, 16384, 2, 2, 3, 2, 0, 0, 20, 0, 0);
SET @ScriptName = 'aura_ascension_vitality_surge';
DELETE FROM `spell_script_names` WHERE `spell_id` = 503718 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (503718, @ScriptName);
DELETE FROM `spell_group` WHERE `id` = 2000181 AND `spell_id` = 503719;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES (2000181, 503719);
