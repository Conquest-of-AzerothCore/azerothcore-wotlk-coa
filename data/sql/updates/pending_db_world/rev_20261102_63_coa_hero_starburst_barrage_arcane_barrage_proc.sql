-- Starburst Barrage (#10722): the tooltip names Starfire and Arcane Barrage, which sit in different spell families, so
-- spell_proc no longer filters by family and aura_hero_druid_starburst_barrage accepts only those two spells.
DELETE FROM `spell_proc` WHERE `SpellId` IN (284222, 979137);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(284222, 0, 0, 0, 0, 0, 0x10000, 0x1, 0x2, 0, 0, 0x2, 0, 100, 0, 0),
(979137, 0, 0, 0, 0, 0, 0x10000, 0x1, 0x2, 0, 0, 0x2, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_hero_druid_starburst_barrage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(284222, 'aura_hero_druid_starburst_barrage'),
(979137, 'aura_hero_druid_starburst_barrage');
