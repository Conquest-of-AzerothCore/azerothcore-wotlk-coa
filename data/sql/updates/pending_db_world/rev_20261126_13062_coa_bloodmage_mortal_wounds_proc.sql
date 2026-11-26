-- Mortal Wounds (504292): "Your direct harmful critical strikes with spells and abilities now cause the
-- target to bleed for ... over $504291d."
-- rev_20260920_50_bloodmage_crit_procs.sql inserted the spell_proc row with AttributesMask 0, leaving
-- PROC_ATTR_TRIGGERED_CAN_PROC (2) unset. Because 504292 lacks SPELL_ATTR3_CAN_PROC_FROM_PROCS,
-- Aura::GetProcEffectMask rejected every triggered direct harmful spell without SPELL_ATTR3_NOT_A_PROC
-- (Blood Shard 504115, Hematoma 803392, Clotting 806214, Purify Blood 573273, etc.), all of which proc
-- Mortal Wounds 504291 on Ascension. Set AttributesMask = 2 (PROC_ATTR_TRIGGERED_CAN_PROC) while keeping
-- ProcFlags 69904 (direct spells/abilities, excluding white swings and periodic ticks) and HitMask 2 (crit).
DELETE FROM `spell_proc` WHERE `SpellId` = 504292;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504292, 0, 0, 0, 0, 0, 69904, 1, 2, 2, 2, 0, 0, 0, 0, 0);
