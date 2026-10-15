--
-- Battleweaver (#1752): effective healing grants the native haste/damage stack.
DELETE FROM `spell_proc` WHERE `SpellId` IN (300733);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(300733, 0, 0, 0, 0, 0, 278528, 2, 2, 3, 0, 0, 0, 100, 0, 0);

-- Reuse the existing Primalist owner/effective-healing predicate.
SET @ScriptName = 'aura_ascension_vitality_surge';
DELETE FROM `spell_script_names` WHERE `spell_id` = 300733 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (300733, @ScriptName);
