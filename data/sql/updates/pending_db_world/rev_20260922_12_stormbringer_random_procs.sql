-- Stormbringer passives whose proc aura never fires: Spell.dbc ProcFlags 0 with no `spell_proc` row.
--
-- SpellMgr::LoadSpellProcs skips a record with no DBC proc flags ("Skip if no proc flags in DBC",
-- src/server/game/Spells/SpellMgr.cpp), so no fallback entry is generated; Aura::GetProcEffectMask then
-- returns 0 for any aura with no proc entry ("only auras with spell proc entry can trigger proc",
-- src/server/game/Spells/Auras/SpellAuras.cpp). Each spell below carries a live
-- SPELL_AURA_PROC_TRIGGER_SPELL effect that has never fired on this realm. Same defect and same shape as
-- data/sql/updates/pending_db_world/rev_20260921_40_ranger_dead_procs.sql.
--
-- Chance stays 0 throughout so each record's own ProcChance is used
-- ("if (!procEntry.Chance && !procEntry.ProcsPerMinute) procEntry.Chance = float(spellInfo->ProcChance)").
--
-- Every Stormbringer damage spell inspected has DmgClass 1 (SPELL_DAMAGE_CLASS_MAGIC), so the event these
-- rows key on is ProcFlags 65536 = PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG with SpellTypeMask 1
-- (PROC_SPELL_TYPE_DAMAGE) and SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT). PROC_FLAG_DONE_PERIODIC (262144)
-- stays unset because every tooltip below says direct damage, and AttributesMask stays 0 so
-- PROC_ATTR_TRIGGERED_CAN_PROC is not granted and triggered child spells cannot feed the proc.

-- #1684 Storm Chaser (300612)
-- tooltip: Dealing direct spell damage now has a 33% chance to reduce the cast time of your next
-- Call Lightning by 15% for 10 sec, stacking 2 times.
-- 300612 is SPELL_ATTR0_PASSIVE with ProcChance 33, ProcFlags 0 and one effect: SPELL_EFFECT_APPLY_AURA (6)
-- with EffectApplyAuraName 42 (SPELL_AURA_PROC_TRIGGER_SPELL) on EffectTriggerSpell 300915. The buff is
-- already native: 300915 is aura 108 (SPELL_AURA_ADD_PCT_MODIFIER) with EffectMiscValue 10
-- (SPELLMOD_CASTING_TIME), EffectBasePoints -16 / EffectDieSides 1 -> -15, StackAmount 2, DurationIndex 1
-- (SpellDuration.dbc 1 = 10000 ms) and EffectSpellClassMask word 1 = 17 = bit 0 | bit 4, which selects
-- Torrential Wrath 503352 (SpellFamilyFlags[1] = 1) and Call Lightning 500040 (SpellFamilyFlags[1] = 16)
-- inside SpellFamilyName 22. HitMask 3 = PROC_HIT_NORMAL | PROC_HIT_CRITICAL, excluding PROC_HIT_ABSORB,
-- which the engine would otherwise add by default for a DONE proc: a fully absorbed hit deals no damage.

-- #1800 Thunder Grip (301219)
-- tooltip: Direct damage dealt now has a 30% chance to apply Thunder Grip to enemies. Thunder Grip prevents
-- enemies from mounting, fleeing, and increasing their movement speed above normal movement speed for 8 sec.
-- 301219 is SPELL_ATTR0_PASSIVE with ProcChance 30, ProcFlags 0 and aura 42 on EffectTriggerSpell 301220.
-- The debuff is already native: 301220 has Mechanic 8, DurationIndex 31 (SpellDuration.dbc 31 = 8000 ms) and
-- two effects on TARGET_UNIT_TARGET_ENEMY - aura 92 (SPELL_AURA_PREVENTS_FLEEING, handled by
-- AuraEffect::HandlePreventFleeing) and aura 191 (SPELL_AURA_USE_NORMAL_MOVEMENT_SPEED, handled by
-- AuraEffect::HandleAuraModUseNormalSpeed). The mount clause has no aura vehicle in this core and is not
-- addressed here; the report is about the missing proc.

-- #3638 Waterfall (806412) - PARTIAL
-- tooltip: Dealing critical damage now reduces all of your cooldowns by 0.5 sec.
-- 806412 is SPELL_ATTR0_PASSIVE with ProcChance 100, ProcFlags 0 and aura 42 on EffectTriggerSpell 807661.
-- 807661 is already native: its three effects are 165 (SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN, handled by
-- Spell::EffectAscensionModifyCooldown) on TARGET_UNIT_CASTER with EffectBasePoints -501 / EffectDieSides 1
-- -> -500 ms and EffectMiscValue 707365 (Overload Mechanical), 500932 (Gust of Wind) and 503352 (Torrential
-- Wrath). HitMask 2 = PROC_HIT_CRITICAL alone, because the mechanic is critical strikes only.
-- This row restores the proc event. It does not deliver the tooltip's "all of your cooldowns": Spell.dbc has
-- three effect slots and the shipped record names three spell ids, so "all" has no data vehicle. 806412 also
-- says "critical damage" while its own trigger 807661 says "critical Froststorm Damage"; the rows below apply
-- no SchoolMask, matching the talent's own string. Both points are left for a maintainer.

DELETE FROM `spell_proc` WHERE `SpellId` IN (300612, 301219, 806412);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(300612, 0, 0, 0, 0, 0, 65536, 1, 2, 3, 0, 0, 0, 0, 0, 0),
(301219, 0, 0, 0, 0, 0, 65536, 1, 2, 3, 0, 0, 0, 0, 0, 0),
(806412, 0, 0, 0, 0, 0, 65536, 1, 2, 2, 0, 0, 0, 0, 0, 0);
