DELETE FROM `spell_proc` WHERE `SpellId` = 680678;
INSERT INTO `spell_proc` (
    `SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
    `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
    `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`
) VALUES
(680678, 0, 26, 0, 10240, 0, 81920, 7, 1, 0, 8, 0, 0, 100, 0, 1);
