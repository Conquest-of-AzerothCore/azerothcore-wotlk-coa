-- Time Stream Slasher and Blister Chain never procced: their proc dummies carry DBC ProcFlags 0 and the world had no
-- spell_proc row, so Aura::GetProcEffectMask found no entry and the chance roll never happened (#10732).
--
-- Time Stream Slasher: "Your melee attacks and direct damaging spells have a chance to ... cause an additional Arcane
-- damage". ProcFlags 65556 = PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS |
-- PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG. Covers 202053 and the worldforged tiers 312573, 316573, 320573.
--
-- Blister Chain: "your attacks have a chance to blister the target dealing ... Fire damage". ProcFlags 340 =
-- PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS | PROC_FLAG_DONE_RANGED_AUTO_ATTACK |
-- PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS. Covers 304158 and the worldforged tiers 313273, 317273, 321273.
--
-- SpellTypeMask 1 (damage) at the hit phase. Chance is left 0 so SpellMgr::LoadSpellProcs defers to the records' own
-- ProcChance (7 and 25), and Cooldown stays 0 because neither tooltip names an internal cooldown. Periodic ticks are
-- not proc events.
DELETE FROM `spell_proc` WHERE `SpellId` IN (202053, 312573, 316573, 320573, 304158, 313273, 317273, 321273);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(202053, 0, 0, 0, 0, 0, 65556, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312573, 0, 0, 0, 0, 0, 65556, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(316573, 0, 0, 0, 0, 0, 65556, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(320573, 0, 0, 0, 0, 0, 65556, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(304158, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(313273, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(317273, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(321273, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 0, 0);
