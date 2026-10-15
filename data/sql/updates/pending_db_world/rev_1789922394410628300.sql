--
-- Earth Pummeling (#1282): direct Geode hits apply the native spell-critical vulnerability.
DELETE FROM `spell_script_names` WHERE `spell_id` = 560182 AND `ScriptName` = 'aura_ascension_primalist_direct_damage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (560182, 'aura_ascension_primalist_direct_damage');
DELETE FROM `spell_proc` WHERE `SpellId` = 560182;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560182, 0, 37, 4096, 32, 0, 87312, 1, 2, 3, 2, 0, 0, 100, 0, 0);
