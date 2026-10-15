-- Pure Chaos (807569): "While Incarnation of Chaos is active, all damage dealt now has a $h% chance to
-- lock yourself in a time loop for $807571d ... you cast Chromatic Shard free of cost, repeating every
-- $807571t1 sec." $h renders the record's own ProcChance, which Spell.dbc gives as 10. The talent's
-- single effect is aura 42 (proc trigger spell) on Time Loop 807571, which is fully native: aura 23
-- (periodic trigger spell, Amplitude 1000) on 807989 -> Chromatic Shard 801292 as a triggered, and so
-- free, cast; aura 33 (mod decrease speed); and aura 263 (SPELL_AURA_ALLOW_ONLY_ABILITY,
-- AuraEffect::HandleAuraAllowOnlyAbility) class-masked to Chromatic Shard's SpellFamilyFlags word1 4096.
-- Duration index 27 = 3000 ms, matching the tooltip's 3 sec. Only the proc gate was missing: Spell.dbc
-- gives 807569 ProcFlags 0, SpellMgr::LoadSpellProcs generates no entry for such a record, and
-- Aura::GetProcEffectMask returns 0 without one.
-- Columns, all read from Spell.dbc and from the core's proc call sites this session:
--   SpellFamilyName 0 / all SpellFamilyMask 0 - "all damage dealt" names no ability.
--   ProcFlags 332116 - every DONE damage flag a Chronomancer can generate:
--     PROC_FLAG_DONE_MELEE_AUTO_ATTACK (4) | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS (16) |
--     PROC_FLAG_DONE_RANGED_AUTO_ATTACK (64) | PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS (256) |
--     PROC_FLAG_DONE_SPELL_NONE_DMG_CLASS_NEG (4096) | PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG (65536) |
--     PROC_FLAG_DONE_PERIODIC (262144). The main-hand/off-hand flags are left out on purpose: they are
--     set alongside PROC_FLAG_DONE_MELEE_AUTO_ATTACK and would double the events for one swing.
--   SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE) - "damage dealt": Unit::ProcSkillsAndAuras computes DAMAGE
--     only when the event carries a DamageInfo with damage or absorb.
--   SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT) - the damage is done at the HIT phase, and it is also the
--     default procPhase of the periodic-tick call; the auto-attack flags are outside
--     REQ_SPELL_PHASE_PROC_FLAG_MASK, so this column does not restrict them.
--   HitMask 0 - default NORMAL|CRITICAL|ABSORB for a DONE proc.
--   Chance 10 - the record's own ProcChance and the number the tooltip renders.
DELETE FROM `spell_proc` WHERE `SpellId` = 807569;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(807569, 0, 0, 0, 0, 0, 332116, 1, 2, 0, 0, 0, 0, 10, 0, 0);

-- "While Incarnation of Chaos is active" cannot be expressed by spell_proc, so it becomes a condition on
-- the proc itself. Aura::GetProcEffectMask evaluates CONDITION_SOURCE_TYPE_SPELL_PROC (24) against a
-- ConditionSourceInfo built from the event's actor and action target, so ConditionTarget 0 is the
-- Chronomancer dealing the damage and CONDITION_AURA (1) on 570067 Incarnation of Chaos is the gate.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 24 AND `SourceGroup` = 0 AND `SourceEntry` = 807569 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(24, 0, 807569, 0, 0, 1, 0, 570067, 0, 0, 0, 0, 0, '', 'Pure Chaos only procs while Incarnation of Chaos is active');
