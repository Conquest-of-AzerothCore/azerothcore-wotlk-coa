--
-- Resources of the Earth (#615): damaging critical strikes grant party Replenishment.
DELETE FROM `spell_proc` WHERE `SpellId` IN (560548);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560548, 0, 0, 0, 0, 0, 332116, 1, 2, 2, 2, 2, 0, 100, 0, 0);
