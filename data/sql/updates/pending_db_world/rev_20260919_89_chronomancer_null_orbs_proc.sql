-- Null Orbs (572722): "Periodic critical damage dealt now has a $h% chance to grant Null Orbs for
-- $572723d." $h renders the record's own ProcChance, which Spell.dbc gives as 20. 572723 is an 8 s
-- self-buff with two SPELL_AURA_ADD_FLAT_MODIFIER (107) effects, both MiscValue 15
-- (SPELLMOD_CRIT_DAMAGE_BONUS), class-masked to Anomaly Spike 503826 (word0 134217728) and Chromatic
-- Shard 801292 (word2 33554432) - native spellmods that work as soon as the buff lands. Only the proc
-- gate was missing: Spell.dbc gives 572722 ProcFlags 0, SpellMgr::LoadSpellProcs generates no entry for
-- such a record, and Aura::GetProcEffectMask returns 0 without one.
-- Columns, all read from Spell.dbc and from the core's periodic-tick proc call this session:
--   SpellFamilyName 0 / all SpellFamilyMask 0 - "periodic damage dealt" names no ability.
--   ProcFlags 262144 (PROC_FLAG_DONE_PERIODIC) - the flag AuraEffect::HandlePeriodicDamageAurasTick sets
--     for the caster of a damaging tick.
--   SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE) - the tick passes a DamageInfo carrying the tick's damage.
--   SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT) - the tick uses ProcSkillsAndAuras' default procPhase, and
--     PROC_FLAG_DONE_PERIODIC is inside REQ_SPELL_PHASE_PROC_FLAG_MASK.
--   HitMask 2 (PROC_HIT_CRITICAL) - the tooltip restricts the trigger to *critical* periodic damage. The
--     tick sets procEx |= crit ? PROC_EX_CRITICAL_HIT : PROC_EX_NORMAL_HIT, and PROC_EX_CRITICAL_HIT and
--     PROC_HIT_CRITICAL are both 0x2. Without this column SpellMgr::CanSpellTriggerProcOnEvent would
--     apply the DONE default NORMAL|CRITICAL|ABSORB and proc on ordinary ticks too.
--   Chance 20 - the record's own ProcChance and the number the tooltip renders.
DELETE FROM `spell_proc` WHERE `SpellId` = 572722;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(572722, 0, 0, 0, 0, 0, 262144, 1, 2, 2, 0, 0, 0, 20, 0, 0);
