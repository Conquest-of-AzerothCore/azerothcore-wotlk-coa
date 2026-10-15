-- Altered Course: trigger the existing speed buff once per Discharge cast, even without enemies nearby.
-- Family 22 / mask1 0x1000 also covers Ride the Lightning, which inherits Discharge modifiers.
-- ProcFlags 65536: done negative magic spell; SpellPhaseMask 1: cast, not each target hit.
DELETE FROM `spell_proc` WHERE `SpellId` = 707053;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(707053, 0, 22, 0, 4096, 0, 65536, 0, 1, 0, 0, 0, 0, 100, 0, 0);
