-- Reborn Blade Twisting (1131124, 1131126) takes the Hero talent's row through its stock twin, which procs from Shiv
-- alone. The Reborn chain has its own: its Spell.dbc flags and chance (damaging melee attacks, 10%).
DELETE FROM `spell_proc` WHERE `SpellId` = -1131124;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-1131124, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0);
