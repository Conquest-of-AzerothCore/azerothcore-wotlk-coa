--
-- Earthmother's Empowerment (#1755): Hand of the Earthmother grants its target five seconds of dodge.
DELETE FROM `spell_proc` WHERE `SpellId` IN (300738);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(300738, 0, 37, 0, 8, 0, 16384, 2, 2, 3, 0, 0, 0, 100, 0, 0);
