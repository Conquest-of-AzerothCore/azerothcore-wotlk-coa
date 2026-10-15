--
-- Lacerations (#2001): only positive melee critical hits apply the non-stacking bleed debuff.
DELETE FROM `spell_proc` WHERE `SpellId` = 560286;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560286, 0, 0, 0, 0, 0, 20, 1, 2, 2, 2, 0, 0, 100, 0, 0);
SET @ScriptName = 'aura_ascension_primalist_direct_damage';
DELETE FROM `spell_script_names` WHERE `spell_id` = 560286 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (560286, @ScriptName);
DELETE FROM `spell_group` WHERE `id` = 1033 AND `spell_id` = 560288;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES (1033, 560288);
