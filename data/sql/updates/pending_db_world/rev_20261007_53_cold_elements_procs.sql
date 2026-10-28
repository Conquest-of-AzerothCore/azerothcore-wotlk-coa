DELETE FROM `spell_proc` WHERE `SpellId` IN (520138, 802648);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(520138, 0, 38, 0, 0, 0x20040, 0x10000, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0),
(802648, 0, 38, 0, 0x8000000, 0, 0x10000, 0, 0x1, 0, 0x8, 0, 0, 0, 0, 1);
