--
-- Wild Carnage (#1900): direct Seismic Spike damage grants the native six-second chain modifier.
DELETE FROM `spell_proc` WHERE `SpellId` = 503717;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(503717, 0, 37, 16, 0, 0, 87312, 1, 2, 3, 0, 0, 0, 100, 0, 0);
SET @ScriptName = 'aura_ascension_primalist_direct_damage';
DELETE FROM `spell_script_names` WHERE `spell_id` = 503717 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (503717, @ScriptName);
