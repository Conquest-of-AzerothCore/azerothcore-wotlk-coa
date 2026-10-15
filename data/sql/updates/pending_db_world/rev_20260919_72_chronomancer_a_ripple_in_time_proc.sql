-- A Ripple In Time (706096): "Your damaging and healing critical strikes now reduce the remaining
-- cooldown of Ripple by $/1000;706783s1 sec." Effect 0 is aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL)
-- triggering 706783, whose single effect is SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN (165) with
-- MiscValue 806296 (Ripple, RecoveryTime 30000) and BasePoints -1001 -> -1000 ms, handled natively by
-- Spell::EffectAscensionModifyCooldown / ModifyAscensionCooldown. Spell.dbc gives 706096's record
-- ProcFlags 0x0 and no `spell_proc` row existed, so SpellMgr::LoadSpellProcs skipped it and
-- Aura::GetProcEffectMask returned 0: the cooldown reduction never happened.
-- The tooltip names no ability, so the row carries no SpellFamilyName or family mask - any damaging or
-- healing critical strike the player lands is a trigger.
-- ProcFlags 87040 = PROC_FLAG_DONE_SPELL_NONE_DMG_CLASS_POS (0x400) | ..._NONE_DMG_CLASS_NEG (0x1000)
-- | ..._MAGIC_DMG_CLASS_POS (0x4000) | ..._MAGIC_DMG_CLASS_NEG (0x10000). Spell.cpp's
-- TargetInfo::DoDamageAndTriggers derives the bit from DmgClass (magic or none) and from
-- `positive`, which is false when the cast dealt damage and true when it healed; the tooltip covers
-- both directions, so all four bits are set. Auto-attack and weapon-class flags are deliberately left
-- out: the Chronomancer's damaging and healing abilities are spells, and including melee/ranged swing
-- flags would make a caster talent fire off white hits the tooltip does not mention.
-- SpellTypeMask 3 = PROC_SPELL_TYPE_DAMAGE | PROC_SPELL_TYPE_HEAL, which is what restricts the row to
-- events that actually dealt damage or healing: Unit::ProcSkillsAndAuras assigns PROC_SPELL_TYPE_HEAL
-- when the event carries a HealInfo with a heal, PROC_SPELL_TYPE_DAMAGE when it carries damage or an
-- absorb, and PROC_SPELL_TYPE_NO_DMG_HEAL otherwise - the last case is excluded here.
-- SpellPhaseMask 2 = PROC_SPELL_PHASE_HIT, the phase where damage and healing exist.
-- HitMask 2 = PROC_HIT_CRITICAL is the tooltip's "critical strikes" clause; without it
-- SpellMgr::CanSpellTriggerProcOnEvent defaults done procs to normal + critical + absorb.
-- DisableEffectsMask 2 disables effect 1 (SPELL_AURA_REDUCE_PUSHBACK), which is not a proc effect.
-- Chance is the record's own ProcChance (100).
DELETE FROM `spell_proc` WHERE `SpellId` = 706096;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706096, 0, 0, 0, 0, 0, 87040, 3, 2, 2, 0, 2, 0, 100, 0, 0);
