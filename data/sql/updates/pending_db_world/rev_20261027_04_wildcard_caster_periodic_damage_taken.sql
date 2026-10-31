START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` IN (277471, 283851);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(277471, 16, 0, 0, 0, 0, 524288, 1, 2, 3, 2, 6, 0, 100, 0, 8),
(283851, 32, 0, 0, 0, 0, 524288, 1, 2, 3, 2, 6, 0, 100, 0, 5);
COMMIT;
