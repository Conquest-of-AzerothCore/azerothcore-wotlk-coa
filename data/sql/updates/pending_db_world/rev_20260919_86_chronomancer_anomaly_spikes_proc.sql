-- Anomaly Spikes (503825): "Periodic damage dealt now has a $h% chance to launch an Anomaly Spike at
-- your target." $h renders the record's own ProcChance, which Spell.dbc gives as 8. The talent's single
-- effect is aura 42 (proc trigger spell) on Anomaly Spike 503826, a plain SPELL_EFFECT_SCHOOL_DAMAGE that
-- already carries its own spell_bonus_data row (rev_20260914_15_chronomancer_ripple.sql) and a scaling
-- entry, so only the proc gate was missing: Spell.dbc gives 503825 ProcFlags 0, SpellMgr::LoadSpellProcs
-- generates nothing for a record without proc flags, and Aura::GetProcEffectMask returns 0 without an
-- entry, so 503826 was never launched.
-- Columns, all read from Spell.dbc and from the core's periodic-tick proc call this session:
--   SpellFamilyName 0 / all SpellFamilyMask 0 - the tooltip says "periodic damage dealt", naming no
--     ability, and SpellInfo::IsAffected passes everything when the row's family name is zero.
--   ProcFlags 262144 (PROC_FLAG_DONE_PERIODIC) - AuraEffect::HandlePeriodicDamageAurasTick
--     (src/server/game/Spells/Auras/SpellAuraEffects.cpp) sets exactly this flag for the caster of a
--     damaging tick.
--   SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE) - that call passes a DamageInfo with the tick's damage, so
--     Unit::ProcSkillsAndAuras computes DAMAGE.
--   SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT) - the tick call uses ProcSkillsAndAuras' default procPhase,
--     which Unit.h declares as PROC_SPELL_PHASE_HIT, and PROC_FLAG_DONE_PERIODIC is inside
--     REQ_SPELL_PHASE_PROC_FLAG_MASK, so the phase is checked.
--   HitMask 0 - default NORMAL|CRITICAL|ABSORB for a DONE proc; the tooltip makes no hit-result claim.
--   AttributesMask 0 - Anomaly Spike's damage is direct, not periodic, so it cannot re-enter this row.
--   Chance 8 - the record's own ProcChance and the number the tooltip renders.
DELETE FROM `spell_proc` WHERE `SpellId` = 503825;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(503825, 0, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 8, 0, 0);
