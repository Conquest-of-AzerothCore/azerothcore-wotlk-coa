DELETE FROM `spell_proc` WHERE `SpellId` = 274473;
INSERT INTO `spell_proc` (
  `SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
  `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
  `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`
) VALUES
(274473, 0, 11, 0, 0, 4, 16, 1, 2, 3, 0, 0, 0, 100, 0, 0);
