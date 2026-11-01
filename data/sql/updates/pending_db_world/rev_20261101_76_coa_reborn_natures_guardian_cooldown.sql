-- Reborn Nature's Guardian 1130881-1130886 is built differently from stock 30881 and is given no copy of the stock
-- chain's row, which carries the tooltip's 30 sec cooldown. The Reborn chain takes it.
DELETE FROM `spell_proc` WHERE `SpellId` = -1130881;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-1130881, 0, 0, 0, 0, 0, 0, 0x1, 0, 0, 0, 0, 0, 0, 30000, 0);
