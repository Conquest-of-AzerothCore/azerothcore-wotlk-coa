-- Reborn Taste for Torment (1118774, 1118775) has neither Spell.dbc proc flags nor a proc entry, so its Soul Gorge
-- cooldown reset (1118776) never fired. It procs from Searing Pain's damage at its Spell.dbc chance (15/30%); effect 0,
-- the Soul Gorge healing modifier, takes no part.
DELETE FROM `spell_proc` WHERE `SpellId` IN (1118774, 1118775);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1118774, 0, 5, 0x100, 0, 0, 0x10000, 0x1, 0x2, 0, 0, 0x1, 0, 0, 0, 0),
(1118775, 0, 5, 0x100, 0, 0, 0x10000, 0x1, 0x2, 0, 0, 0x1, 0, 0, 0, 0);
