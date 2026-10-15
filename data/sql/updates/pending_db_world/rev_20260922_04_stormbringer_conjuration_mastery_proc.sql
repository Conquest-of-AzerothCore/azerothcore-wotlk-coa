-- Stormbringer Conjuration Mastery 300595 (#1673): "Your Conjure Storm now refunds 10 Static."
--
-- Retracts the spell_proc row this file used to add. Conjure Storm 800227's cast-phase proc always reaches
-- AuraEffect::HandleProcTriggerSpellAuraProc with a null action target: Spell::cast passes nullptr as the
-- CAST-phase proc's target (src/server/game/Spells/Spell.cpp, the ProcSkillsAndAuras(..., PROC_SPELL_PHASE_CAST)
-- call), and since the proc's own aura target equals the actor, HandleProcTriggerSpellAuraProc resolves the
-- trigger's target from that null action target instead of falling back to the caster. The triggered spell
-- 804084 "Add 10 Static" opens with a SPELL_EFFECT_DUMMY on TARGET_UNIT_TARGET_ANY, which needs an explicit
-- unit target; SpellInfo::CheckExplicitTarget rejects the null target with SPELL_FAILED_BAD_TARGETS before any
-- effect of 804084 runs (masked to SPELL_FAILED_DONT_REPORT for a triggered cast), so the Static effect never
-- fires either. Confirmed against the regression scenario's cast_failures record (reason 27, spell 804084):
-- observed 30 Static after the DISCRIMINATING cast, not the 40 the passive should leave.
--
-- Switching SpellPhaseMask to the HIT phase would supply a real target, but Conjure Storm's first effect is an
-- instant SPELL_EFFECT_SCHOOL_DAMAGE hitting every enemy in its target area (TARGET_UNIT_DEST_AREA_ENEMY,
-- MaxAffectedTargets 0), so a HIT-phase proc would refund 10 Static per enemy struck instead of once per cast,
-- contradicting the tooltip. The refund is now cast directly from the module's existing on-cast Stormbringer
-- talent hook (modules/mod-ascension-compat/src/AscensionStormbringerTalents.cpp,
-- stormbringer_talent_casts::OnSpellCast), which already casts 804084 on the caster for Critical Circuit: it
-- fires exactly once per completed cast, always with the caster as an explicit target, independent of the
-- proc/aura pipeline this row could not use correctly.
START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` = 300595;
COMMIT;
