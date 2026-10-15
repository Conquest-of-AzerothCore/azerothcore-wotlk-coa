--
-- Mountain Giant (#658): autoattacks grant Aftershock; one Geode Barrage or Earthquake consumes it.
DELETE FROM `spell_proc` WHERE `SpellId` IN (680395, 301086);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680395, 0, 0, 0, 0, 0, 4, 1, 2, 3, 2, 0, 0, 20, 0, 0),
(301086, 0, 37, 2048, 0, 268435456, 65536, 0, 1, 0, 8, 0, 0, 100, 0, 1);
