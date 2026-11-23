DELETE FROM `spell_proc` WHERE `SpellId` = 283244;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Expunge: Chimera Shot (family 9 flag 2 0x1) or Mongoose Bite (flag 2 0x2000000) hits apply Cobra Venom 283245;
-- the DBC ProcFlags (ranged class only) and class mask (Steady Shot flag 1 0x1) match neither
(283244, 0, 9, 0x0, 0x0, 0x2000001, 0x110, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);
