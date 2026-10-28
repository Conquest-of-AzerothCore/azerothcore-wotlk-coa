DELETE FROM `spell_proc` WHERE `SpellId` = 680692;
INSERT INTO `spell_proc` (
    `SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
    `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
    `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`
) VALUES
(680692, 0, 26, 524288, 8192, 0, 81920, 3, 2, 0, 0, 6, 0, 100, 0, 0);
