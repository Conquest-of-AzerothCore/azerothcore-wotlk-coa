--
-- Stonefaced (#1189): each completed Seismic cast grants the native two Earth's Rage stacks.
DELETE FROM `spell_proc` WHERE `SpellId` = 706201;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706201, 0, 37, 80, 4194560, 263168, 81936, 0, 4, 0, 0, 0, 0, 100, 0, 0);
