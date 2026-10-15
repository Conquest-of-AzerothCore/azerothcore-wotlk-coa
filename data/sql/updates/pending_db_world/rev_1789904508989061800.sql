--
-- Geomolding (#644): Tremor periodic damage grants stacks; the next Terrasurge consumes them all.
DELETE FROM `spell_proc` WHERE `SpellId` IN (560169, 560170);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560169, 0, 37, 64, 0, 0, 262144, 1, 2, 3, 2, 0, 0, 100, 0, 0),
(560170, 0, 37, 8, 0, 0, 65536, 0, 4, 0, 8, 0, 0, 100, 0, 1);
