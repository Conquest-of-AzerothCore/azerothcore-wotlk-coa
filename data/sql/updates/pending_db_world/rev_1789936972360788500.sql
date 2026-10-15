--
-- Earthmother's Precision (#1985): Seismic Crash applies the shared spell-hit debuff.
DELETE FROM `spell_proc` WHERE `SpellId` = 555723;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(555723, 0, 37, 0, 4194304, 0, 332116, 1, 2, 3, 2, 0, 0, 100, 0, 0);
