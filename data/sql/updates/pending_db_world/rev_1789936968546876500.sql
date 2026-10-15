--
-- Thorns (#1931): physical damage dealt/taken can root; only direct damage can break the root.
DELETE FROM `spell_proc` WHERE `SpellId` = 504732;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504732, 1, 0, 0, 0, 0, 996348, 1, 2, 3, 2, 0, 0, 10, 0, 0);
SET @ScriptName = 'aura_ascension_primalist_thorns';
DELETE FROM `spell_script_names` WHERE `spell_id` = 504732 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (504732, @ScriptName);
DELETE FROM `spell_proc` WHERE `SpellId` = 504784;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504784, 0, 0, 0, 0, 0, 139944, 1, 2, 3, 2, 0, 0, 40, 0, 0);
