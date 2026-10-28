-- Blood Trails (#510, 804858): "Periodic damage and healing now causes targets to spill a pool of blood
-- beneath them." Effect 1 is aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL) on Blood Trail 804857, DBC ProcChance
-- 100, but Spell.dbc gives 804858 ProcFlags 0 and no spell_proc row existed, so SpellMgr::LoadSpellProcs
-- skipped the record and the aura could never fire. Same dead-proc shape as the sibling fixes merged
-- 2026-09-20 (rev_20260920_51, rev_20260920_58).
--
-- ProcFlags 262144 (PROC_FLAG_DONE_PERIODIC, SpellMgr.h:139) - both AuraEffect::HandlePeriodicDamageAurasTick
-- and AuraEffect::HandlePeriodicHealAurasTick assign procAttacker = PROC_FLAG_DONE_PERIODIC for the caster
-- of a tick (SpellAuraEffects.cpp), so this single flag already covers the tooltip's "damage and healing".
-- SpellTypeMask 3 (PROC_SPELL_TYPE_DAMAGE | PROC_SPELL_TYPE_HEAL) - Unit::ProcSkillsAndAuras derives the
-- spell type from the tick's own damage/heal info (Unit.cpp:7312-7327), so restricting to these two bits
-- keeps the row to exactly the clauses the tooltip names.
-- SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT) - the periodic tick calls omit procPhase, whose default is
-- PROC_SPELL_PHASE_HIT, and PROC_FLAG_DONE_PERIODIC is inside REQ_SPELL_PHASE_PROC_FLAG_MASK, so the phase
-- is checked.
-- SchoolMask/SpellFamilyName/SpellFamilyMask/HitMask/AttributesMask/DisableEffectsMask 0 - the tooltip
-- names no school or ability family and no hit-result requirement; 804858 is a passive, not itself a
-- triggered spell, so PROC_ATTR_TRIGGERED_CAN_PROC does not apply.
-- Chance 0 - defers to the record's own ProcChance (100), per the convention rev_20260919_20 established.
DELETE FROM `spell_proc` WHERE `SpellId` = 804858;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(804858, 0, 0, 0, 0, 0, 262144, 3, 2, 0, 0, 0, 0, 0, 0, 0);
