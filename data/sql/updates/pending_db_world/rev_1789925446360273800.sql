--
-- Nature's Fury (#1758): melee auto attacks have a 20% chance to trigger weapon damage and 5% mana.
DELETE FROM `spell_proc` WHERE `SpellId` IN (300742);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(300742, 0, 0, 0, 0, 0, 4, 1, 0, 3, 0, 0, 0, 20, 0, 0);
