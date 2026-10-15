-- Wonders of Time (560541): "Increases the spell haste of all party and raid members by $s1%.
-- Additionally, all healing done now has a $h% chance to grant you Endless Sands."
-- Effect 0 (SPELL_EFFECT_APPLY_AREA_AURA_RAID with SPELL_AURA_HASTE_SPELLS +3%) and effect 1
-- (SPELL_AURA_ADD_FLAT_MODIFIER, +15 sec duration on Rippling Renewal 560385) are already native.
-- Effect 2 is aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL) triggering 806728 Endless Sands, but Spell.dbc
-- gives 560541's record ProcFlags 0x0 and no `spell_proc` row existed, so SpellMgr::LoadSpellProcs
-- skipped it and Aura::GetProcEffectMask returned 0: the 10% chance never happened.
-- Effect 2 carries no EffectSpellClassMask and the tooltip says "all healing done", so the row carries
-- no SpellFamilyName and no family mask.
-- ProcFlags 279552 = PROC_FLAG_DONE_SPELL_NONE_DMG_CLASS_POS (0x400) |
-- PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_POS (0x4000) | PROC_FLAG_DONE_PERIODIC (0x40000).
-- Only the POS variants of the two spell classes appear, and that is settled by source, not guessed:
-- Spell.cpp's TargetInfo::DoDamageAndTriggers computes
-- `positive = true; if (m_damage > 0) positive = false; else if (!m_healing) { <per-effect scan> }`.
-- A cast that healed has m_healing > 0, so it never reaches the per-effect scan that can flip the
-- verdict, and positive stays true - which is precisely why the merged
-- rev_20260919_30_chronomancer_gift_of_the_timeways_proc.sql needed the NEG variant for Melt Reality,
-- a spell that neither damages nor heals and therefore does reach that scan. The NONE and MAGIC class
-- bits are both present because the Chronomancer's heals include DmgClass 1 spells (Correct the
-- Mistake, Reverse Wound, Fortify Timeline) and DmgClass 0 ones. PROC_FLAG_DONE_PERIODIC covers the
-- tooltip's "all healing done" for heal-over-time ticks, which Spell.cpp classifies as periodic rather
-- than as a spell hit.
-- SpellTypeMask 2 = PROC_SPELL_TYPE_HEAL, which Unit::ProcSkillsAndAuras assigns from
-- `healInfo && healInfo->GetHeal()`; this is what keeps a damaging cast from paying out.
-- SpellPhaseMask 2 = PROC_SPELL_PHASE_HIT. HitMask 0 keeps the default normal-or-critical behaviour.
-- DisableEffectsMask 3 disables effects 0 and 1, which are the haste area aura and the duration
-- modifier, not proc effects. Chance 10 is the record's own ProcChance and matches the tooltip's $h%.
DELETE FROM `spell_proc` WHERE `SpellId` = 560541;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560541, 0, 0, 0, 0, 0, 279552, 2, 2, 0, 0, 3, 0, 10, 0, 0);
