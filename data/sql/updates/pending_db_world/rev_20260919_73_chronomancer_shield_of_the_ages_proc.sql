-- Shield of the Ages (804444): "When hit by a damaging critical strike, your damage taken is reduced by
-- $804445s1%, and healing received is increased by $804445s2% for $804445d, stacking $804445u times."
-- Its only effect is aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL) triggering 804445, which is already fully
-- native - effect 0 is SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN -3 (applied in Unit::SpellDamageBonusTaken /
-- MeleeDamageBonusTaken), effect 1 is SPELL_AURA_ASCENSION_MOD_HEALING_RECEIVED_PCT +5 (applied in
-- Unit.cpp via GetTotalAuraMultiplier(SPELL_AURA_ASCENSION_MOD_HEALING_RECEIVED_PCT)), with duration
-- index 27 (3000 ms) and StackAmount 3, matching "$804445d" and "stacking $804445u times".
-- Spell.dbc gives 804444's record ProcFlags 0x0 and no `spell_proc` row existed, so
-- SpellMgr::LoadSpellProcs skipped it and Aura::GetProcEffectMask returned 0: the buff never appeared.
-- This is a taken-hit proc, so the row uses the TAKEN_* flags rather than the DONE_* ones.
-- ProcFlags 139944 = PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK (0x8) | PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS
-- (0x20) | PROC_FLAG_TAKEN_RANGED_AUTO_ATTACK (0x80) | PROC_FLAG_TAKEN_SPELL_RANGED_DMG_CLASS (0x200)
-- | PROC_FLAG_TAKEN_SPELL_NONE_DMG_CLASS_NEG (0x2000) | PROC_FLAG_TAKEN_SPELL_MAGIC_DMG_CLASS_NEG
-- (0x20000), i.e. every way an incoming attack reaches the victim in Spell.cpp's
-- TargetInfo::DoDamageAndTriggers and Unit::DealMeleeDamage. Only the NEG variants of the two spell
-- classes are used: an incoming hit that dealt damage is classified negative by that same
-- `positive` computation. No SpellFamilyName or family mask is set, because the tooltip names no
-- attacker ability.
-- SpellTypeMask 1 = PROC_SPELL_TYPE_DAMAGE, the tooltip's "damaging". HitMask 2 = PROC_HIT_CRITICAL is
-- the "critical strike" clause and it matters: SpellMgr::CanSpellTriggerProcOnEvent defaults taken
-- procs with no hit mask to normal + critical, which would let every ordinary hit apply the buff.
-- SpellPhaseMask 2 = PROC_SPELL_PHASE_HIT. DisableEffectsMask 0 because 804444 has a single effect and
-- it is the proc effect. Chance is the record's own ProcChance (100).
DELETE FROM `spell_proc` WHERE `SpellId` = 804444;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(804444, 0, 0, 0, 0, 0, 139944, 1, 2, 2, 0, 0, 0, 100, 0, 0);
