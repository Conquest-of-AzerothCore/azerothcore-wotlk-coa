--
-- Terrasmash (#614): positive offhand damage has a thirty-percent chance to launch a Geode.
DELETE FROM `spell_proc` WHERE `SpellId` IN (706220);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706220, 0, 0, 0, 0, 0, 8388608, 1, 2, 3, 2, 4, 0, 30, 0, 0);

SET @ScriptName = 'aura_ascension_primalist_direct_damage';
DELETE FROM `spell_script_names` WHERE `spell_id` = 706220 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (706220, @ScriptName);
