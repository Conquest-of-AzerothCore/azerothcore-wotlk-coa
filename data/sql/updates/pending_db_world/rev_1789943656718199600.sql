--
-- Cataclysm (#2197): Stoneshard casts reset all four Seismic families; resource gains are handled separately.
DELETE FROM `spell_proc` WHERE `SpellId` IN (680444);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680444, 0, 37, 0, 512, 0, 69904, 7, 1, 0, 0, 0, 0, 10, 0, 0);
SET @ScriptName = 'aura_ascension_primalist_cataclysm';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (680444) AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(680444, @ScriptName);
