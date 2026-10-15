--
-- Spinebreaker (#1207): a landed Seismic Grasp applies its 3.5-second root, without retriggering Grasp.
DELETE FROM `spell_proc` WHERE `SpellId` = 537212;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(537212, 0, 37, 0, 0, 262144, 65536, 4, 2, 3, 0, 4, 0, 100, 0, 0);
