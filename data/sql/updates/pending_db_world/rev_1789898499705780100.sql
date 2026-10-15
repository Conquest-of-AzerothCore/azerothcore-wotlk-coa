--
-- One with the Earth (#588): each completed Stoneshard, including triggered repeats, restores four percent Mana.
-- Native effect one already supplies the separate 25 percent Stoneshard/Geode Barrage damage modifier.
DELETE FROM `spell_proc` WHERE `SpellId` = 704402;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(704402, 0, 37, 0, 512, 0, 65536, 0, 4, 0, 2, 2, 0, 100, 0, 0);
