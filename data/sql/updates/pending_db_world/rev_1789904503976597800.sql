--
-- Mountain Mover (#619): avoided incoming attacks grant stacks; Wildclaw consumes the full buff.
DELETE FROM `spell_proc` WHERE `SpellId` IN (805643, 805644);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(805643, 0, 0, 0, 0, 0, 680, 0, 0, 52, 2, 3, 0, 100, 0, 0),
(805644, 0, 37, 1, 0, 0, 16, 0, 4, 0, 8, 0, 0, 100, 0, 1);
