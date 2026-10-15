--
-- Sharpened Claws (#583): direct critical hits grant owner and pet armor penetration.
DELETE FROM `spell_proc` WHERE `SpellId` IN (504226);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504226, 0, 0, 0, 0, 0, 69972, 1, 2, 2, 2, 0, 0, 100, 0, 0);

SET @ScriptName = 'aura_ascension_primalist_direct_damage';
DELETE FROM `spell_script_names` WHERE `spell_id` = 504226 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (504226, @ScriptName);
