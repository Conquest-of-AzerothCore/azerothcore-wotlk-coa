--
-- Ride the Wave (#1774): each Seismic Wave heal buffs its affected ally.
DELETE FROM `spell_proc` WHERE `SpellId` = 300867;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(300867, 0, 37, 0, 256, 0, 16384, 2, 2, 3, 0, 0, 0, 100, 0, 0);
