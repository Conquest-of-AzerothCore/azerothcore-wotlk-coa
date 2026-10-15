-- Hourglass of Eternity (806337): "Periodic damage dealt now has a $h% chance to grant you $504726s1%
-- increased haste for $504726d." $h renders the record's own ProcChance, which Spell.dbc gives as 5;
-- 504726 is a self-buff whose single effect is aura 216 (SPELL_AURA_HASTE_SPELLS, BasePoints 24 = +25%)
-- with duration index 28 = 5000 ms, matching the tooltip. Aura 216 is native
-- (AuraEffect::HandleModCastingSpeed), so the buff works the moment it lands; nothing applied it, because
-- Spell.dbc gives 806337 ProcFlags 0 and SpellMgr::LoadSpellProcs generates no entry for such a record,
-- so Aura::GetProcEffectMask returned 0 for every tick.
-- Columns, all read from Spell.dbc and from the core's periodic-tick proc call this session:
--   SpellFamilyName 0 / all SpellFamilyMask 0 - "periodic damage dealt" names no ability, and
--     SpellInfo::IsAffected passes everything when the row's family name is zero.
--   ProcFlags 262144 (PROC_FLAG_DONE_PERIODIC) - the flag AuraEffect::HandlePeriodicDamageAurasTick sets
--     for the caster of a damaging tick.
--   SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE) - the tick passes a DamageInfo carrying the tick's damage.
--   SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT) - the tick uses ProcSkillsAndAuras' default procPhase, and
--     PROC_FLAG_DONE_PERIODIC is inside REQ_SPELL_PHASE_PROC_FLAG_MASK.
--   HitMask 0 - default NORMAL|CRITICAL|ABSORB for a DONE proc; the tooltip makes no hit-result claim.
--   Chance 5 - the record's own ProcChance and the number the tooltip renders.
--   Cooldown 0 / Charges 0 - the record carries neither.
DELETE FROM `spell_proc` WHERE `SpellId` = 806337;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(806337, 0, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 5, 0, 0);
