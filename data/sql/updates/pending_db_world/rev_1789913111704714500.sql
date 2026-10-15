--
-- Nature's Will (#771): extend Earthshaping once after each completed Seismic cast.
DELETE FROM `spell_proc` WHERE `SpellId` = 560140;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560140, 0, 37, 80, 4194560, 263168, 81936, 0, 4, 0, 0, 0, 0, 100, 0, 0);
