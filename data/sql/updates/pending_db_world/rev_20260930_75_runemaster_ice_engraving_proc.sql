-- Runemaster Weapon Engraving: Ice (653266): the 40% Ice Engraving (653217) proc on damage dealt, as Fire Engraving.
DELETE FROM `spell_proc` WHERE `SpellId` = 653266;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(653266, 0, 0, 0, 0, 0, 0x00010154, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0);
