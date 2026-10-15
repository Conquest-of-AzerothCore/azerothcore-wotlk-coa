--
-- Heavy Handed (#1225): Hand of the Earthmother grants the native armor buff to caster and healed ally.
DELETE FROM `spell_proc` WHERE `SpellId` = 706344;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706344, 0, 37, 0, 8, 0, 16384, 2, 2, 3, 0, 0, 0, 100, 0, 0);
