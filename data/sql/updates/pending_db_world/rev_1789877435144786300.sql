--
-- Rage Rolling (#542): Boulder Dash's cast grants 500 internal Rage (50 visible Rage).
-- Its family bit is unique to the parent; cast phase excludes repeated damage ticks.
DELETE FROM `spell_proc` WHERE `SpellId` = 561191;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(561191, 0, 37, 0, 0, 536870912, 81920, 7, 1, 0, 0, 0, 0, 100, 0, 0);
