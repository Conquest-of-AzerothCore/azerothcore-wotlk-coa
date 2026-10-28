-- Runeslinger 705550 (#2727): "Direct damage dealt has a 5% chance to increase your spell haste by 20% for 5
-- sec." Effect0 is SPELL_AURA_PROC_TRIGGER_SPELL, ProcChance 5 (matches "5%"), trigger 520760 (SPELL_AURA_HASTE_
-- SPELLS, BasePoints 19/DieSides 1 = +20%, DurationIndex 28 = 5000ms, matching "20%"/"5 sec"), but Spell.dbc
-- ProcFlags is 0 and no spell_proc row exists, so it never fires. "Direct damage dealt" is not scoped to one
-- spell family, so this reuses the same generic "any direct damage" mask already established for Earth Engraving
-- 653221 (rev_20260927_91): ProcFlags 0x00010154 (done melee/ranged auto attack, done melee/ranged spell damage
-- class, done harmful magic-class spell damage), SpellTypeMask 0x1 (damage), SpellPhaseMask 0x2 (hit); Chance 0
-- keeps the Spell.dbc 5%.
DELETE FROM `spell_proc` WHERE `SpellId` = 705550;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(705550, 0, 0, 0, 0, 0, 0x00010154, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0);
