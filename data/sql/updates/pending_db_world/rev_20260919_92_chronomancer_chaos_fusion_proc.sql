-- Chaos Fusion (807578): "Increases the duration of Incarnation of Chaos by $/1000;s2 sec and while
-- active your Melt Reality now has no cooldown." Effect 1 (aura 107 ADD_FLAT_MODIFIER, MiscValue 1 =
-- SPELLMOD_DURATION, BasePoints 2999 = +3000 ms, class-masked to Incarnation of Chaos 570067's
-- SpellFamilyFlags word2 8192) is native and already works. Effect 0 is aura 42 (proc trigger spell) on
-- 807755 "Chaos Fusion", a 15 s self-buff whose single effect is aura 108 (ADD_PCT_MODIFIER, MiscValue 11
-- = SPELLMOD_COOLDOWN, BasePoints -101 = -100%) class-masked to Melt Reality's SpellFamilyFlags word1
-- 512 - native the moment it lands. Only the proc gate was missing: Spell.dbc gives 807578 ProcFlags 0,
-- SpellMgr::LoadSpellProcs generates no entry for such a record, and Aura::GetProcEffectMask returns 0
-- without one, so the no-cooldown buff was never applied.
-- Columns, all read from Spell.dbc this session:
--   SpellFamilyName 28 / SpellFamilyMask2 8192 - Incarnation of Chaos 570067's own SpellFamilyName and
--     SpellFamilyFlags word2, the ability whose activation the tooltip ties the buff to.
--   ProcFlags 1024 (PROC_FLAG_DONE_SPELL_NONE_DMG_CLASS_POS) - 570067 has DmgClass 0 (NONE) and is a
--     positive self-transformation (auras 108, 107 and 79, all on implicit target 1), the case Spell.cpp
--     fills in for a positive none-class cast.
--   SpellTypeMask 4 (PROC_SPELL_TYPE_NO_DMG_HEAL) - 570067 has no damage or healing effect, so
--     Unit::ProcSkillsAndAuras computes NO_DMG_HEAL for its HIT-phase event.
--   SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT) - 570067's effects all target TARGET_UNIT_CASTER, so the
--     caster is its own unit target and Spell::DoAllEffectOnTarget raises the HIT-phase event for it.
--   HitMask 0 - default NORMAL|CRITICAL|ABSORB for a DONE proc.
--   Chance 100 - the record's own ProcChance; the tooltip states no percentage.
DELETE FROM `spell_proc` WHERE `SpellId` = 807578;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(807578, 0, 28, 0, 0, 8192, 1024, 4, 2, 0, 0, 0, 0, 100, 0, 0);
