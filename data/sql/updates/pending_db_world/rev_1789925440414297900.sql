--
-- Primal Rage (#1726): a completed Totemic Smash cast restores one Rylak's Bite charge.
DELETE FROM `spell_proc` WHERE `SpellId` = 300690;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(300690, 0, 37, 0, 0, 16, 16, 0, 1, 0, 0, 0, 0, 100, 0, 0);
