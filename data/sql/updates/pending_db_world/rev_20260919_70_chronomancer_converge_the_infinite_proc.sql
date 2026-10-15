-- Converge the Infinite (520045): "Casting Fortify Timeline now grants you Converge the Infinite."
-- Its only effect is aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL) triggering the 520840 buff (+30% damage,
-- +100% crit chance and +1000 ms cast time on Correct the Mistake, class mask word1 2048), but Spell.dbc
-- gives 520045's record ProcFlags 0x0 and no `spell_proc` row existed. SpellMgr::LoadSpellProcs skips a
-- record with no ProcFlags ("Skip if no proc flags in DBC", SpellMgr.cpp), and Aura::GetProcEffectMask
-- returns 0 without a proc entry ("only auras with spell proc entry can trigger proc", SpellAuras.cpp),
-- so the buff could never be granted.
-- Proc on Fortify Timeline, the ability the tooltip names: 804491 is SpellFamilyName 28 with
-- SpellFamilyFlags word1 4194304, DmgClass 1 (magic) and effect 0 SPELL_EFFECT_HEAL.
-- ProcFlags 16384 = PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_POS (SpellMgr.h). The positive variant, not the
-- negative one, is what a heal produces: Spell.cpp's TargetInfo::DoDamageAndTriggers computes
-- `positive = true; if (m_damage > 0) positive = false; else if (!m_healing) { <per-effect scan> }`, so a
-- spell that heals never reaches the per-effect scan and keeps positive == true, and DmgClass 1 then sets
-- PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_POS. (This is why the merged
-- rev_20260919_30_chronomancer_gift_of_the_timeways_proc.sql needed the NEG variant instead: Melt Reality
-- neither damages nor heals, so it does reach the per-effect scan.)
-- SpellTypeMask 2 = PROC_SPELL_TYPE_HEAL: Unit::ProcSkillsAndAuras sets the event's spell type from
-- `healInfo && healInfo->GetHeal()` before any damage test, and Fortify Timeline's hit event carries a
-- HealInfo. SpellPhaseMask 2 = PROC_SPELL_PHASE_HIT; 804491 has no SPELL_ATTR3_SUPPRESS_CASTER_PROCS
-- (AttributesEx3 0x0), so its hit-phase event is delivered. HitMask 0 keeps the default normal-or-critical
-- behaviour. DisableEffectsMask 0 because 520045 has a single effect, and it is the proc effect.
-- Chance is the record's own ProcChance (100 - the tooltip states no percentage).
DELETE FROM `spell_proc` WHERE `SpellId` = 520045;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(520045, 0, 28, 0, 4194304, 0, 16384, 2, 2, 0, 0, 0, 0, 100, 0, 0);
