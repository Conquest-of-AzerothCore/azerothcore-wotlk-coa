-- Reborn Savage Defense 1162600 and its shield 1162606 are built differently from stock 62600/62606 and keep no
-- proc data of their own: the trigger procs on every melee hit instead of on critical strikes only. Each takes its
-- stock spell's row.
DELETE FROM `spell_proc` WHERE `SpellId` IN (1162600, 1162606);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1162600, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0x2, 0, 0, 0, 0, 0, 0),
(1162606, 0, 0, 0, 0, 0, 0, 0, 0, 0x403, 0, 0, 0, 0, 0, 0);
