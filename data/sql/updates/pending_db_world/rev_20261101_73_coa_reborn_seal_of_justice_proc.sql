-- Reborn Seal of Justice 1120164 is built differently from stock 20164 and keeps no proc data of its own: it procs at
-- its Spell.dbc chance, 0. It takes the stock row, 5 procs per minute.
DELETE FROM `spell_proc` WHERE `SpellId` = 1120164;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1120164, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0, 0, 0, 5, 0, 0, 0);
