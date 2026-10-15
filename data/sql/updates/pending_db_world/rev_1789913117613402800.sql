--
-- Vitality Surge (#987): effective direct or periodic healing has a 25% chance to grant raid haste.
DELETE FROM `spell_proc` WHERE `SpellId` = 504214;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504214, 0, 0, 0, 0, 0, 279552, 2, 2, 3, 2, 0, 0, 25, 0, 0);

SET @ScriptName = 'aura_ascension_vitality_surge';
DELETE FROM `spell_script_names` WHERE `spell_id` = 504214 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (504214, @ScriptName);

-- Reuse the existing exclusive-same-effect group for raid spell/melee/ranged haste.
DELETE FROM `spell_group` WHERE `id` = 2000182 AND `spell_id` = 504215;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES (2000182, 504215);
