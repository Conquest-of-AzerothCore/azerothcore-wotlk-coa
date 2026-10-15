--
-- Primal Power (#540): one proc on the Seismic Wave cast, independent of its area hit/heal count.
-- The copied cost modifier is already -50% for every Hand of the Earthmother rank; give it one
-- native charge, consumed only by a cast that actually used that spell modifier.
DELETE FROM `spell_proc` WHERE `SpellId` IN (706216, 805463);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706216, 0, 37, 0, 256, 0, 81920, 7, 1, 0, 0, 0, 0, 100, 0, 0),
(805463, 0, 37, 0, 8, 0, 16384, 2, 1, 0, 8, 0, 0, 100, 0, 1);
