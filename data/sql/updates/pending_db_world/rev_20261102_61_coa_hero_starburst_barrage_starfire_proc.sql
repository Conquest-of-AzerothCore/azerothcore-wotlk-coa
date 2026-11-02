-- Starburst Barrage (#10722): 284222 and the Mystic Enchant rank 979137 carry DBC ProcFlags 16 (melee-class spell
-- hits), but their class mask selects Starfire (family 7, mask 0x4), a magic-class damage spell, so the generated
-- proc never fired. Each Starfire hit now adds a stack (284220, 979138); effect 1 is the Starburst transform.
DELETE FROM `spell_proc` WHERE `SpellId` IN (284222, 979137);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(284222, 0, 7, 0x4, 0, 0, 0x10000, 0x1, 0x2, 0, 0, 0x2, 0, 100, 0, 0),
(979137, 0, 7, 0x4, 0, 0, 0x10000, 0x1, 0x2, 0, 0, 0x2, 0, 100, 0, 0);
