-- Reborn Setup (1113983, 1114070, 1114071) has one effect where stock 13983 has three, so it got no copy of the stock
-- row (-13983) and its generated entry admits only normal and critical hits taken: a dodge never procced it. It takes
-- the stock row: dodges and full resists, once per second.
DELETE FROM `spell_proc` WHERE `SpellId` IN (1113983, 1114070, 1114071);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1113983, 0, 0, 0, 0, 0, 0, 0, 0, 0x18, 0, 0, 0, 0, 1000, 0),
(1114070, 0, 0, 0, 0, 0, 0, 0, 0, 0x18, 0, 0, 0, 0, 1000, 0),
(1114071, 0, 0, 0, 0, 0, 0, 0, 0, 0x18, 0, 0, 0, 0, 1000, 0);
