DELETE FROM `spell_proc` WHERE `SpellId` = 276069;
INSERT INTO `spell_proc` (
    `SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
    `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
    `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`
) VALUES
(276069, 0, 0, 0, 0, 0, 20, 1, 2, 3, 0, 0, 0, 100, 0, 0);
