--
-- Quakeformer (#2196): one 25% roll per Wildclaw or Seismic cast, including nondamaging Grasp.
DELETE FROM `spell_proc` WHERE `SpellId` IN (680419);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680419, 0, 37, 81, 4194304, 262144, 69904, 7, 1, 0, 0, 0, 0, 25, 0, 0);
