--
-- Primal Shaman's Mask (#590): direct damage has a ten-percent chance to launch a Geode.
DELETE FROM `spell_proc` WHERE `SpellId` IN (800185);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(800185, 0, 0, 0, 0, 0, 69972, 1, 2, 3, 2, 0, 0, 10, 0, 0);

SET @ScriptName = 'aura_ascension_primalist_direct_damage';
DELETE FROM `spell_script_names` WHERE `spell_id` = 800185 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (800185, @ScriptName);
