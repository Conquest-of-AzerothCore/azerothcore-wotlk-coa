-- Mark of Order (704488): "Healing done by Fortify Timeline now applies Mark of Order."
-- Its only effect is aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL) triggering 806269, the Mark itself
-- (SPELL_AURA_PERIODIC_TRIGGER_SPELL every 1000 ms plus SPELL_AURA_MOD_HEALING_RECEIVED +10 class-masked
-- to Reverse Wound, 20 sec, StackAmount 5). Spell.dbc gives 704488's record ProcFlags 0x0 and no
-- `spell_proc` row existed, so SpellMgr::LoadSpellProcs skipped it and Aura::GetProcEffectMask returned
-- 0: the Mark was never applied.
-- 704488's aura-42 effect carries no EffectSpellClassMask, so the row must supply the family selector
-- itself. Proc on Fortify Timeline, the ability the tooltip names: 804491 is SpellFamilyName 28 with
-- SpellFamilyFlags word1 4194304, DmgClass 1 (magic) and effect 0 SPELL_EFFECT_HEAL.
-- ProcFlags 16384 = PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_POS. The positive variant is what a heal
-- produces: Spell.cpp's TargetInfo::DoDamageAndTriggers computes
-- `positive = true; if (m_damage > 0) positive = false; else if (!m_healing) { <per-effect scan> }`, so
-- a healing cast keeps positive == true without reaching the per-effect scan, and DmgClass 1 then sets
-- the MAGIC_DMG_CLASS_POS bit.
-- SpellTypeMask 2 = PROC_SPELL_TYPE_HEAL, which Unit::ProcSkillsAndAuras assigns from
-- `healInfo && healInfo->GetHeal()`. SpellPhaseMask 2 = PROC_SPELL_PHASE_HIT; 804491 has no
-- SPELL_ATTR3_SUPPRESS_CASTER_PROCS (AttributesEx3 0x0). Because the event is delivered per healed
-- target, the trigger lands on each ally Fortify Timeline healed, which is what "applies Mark of
-- Order" describes (AuraEffect::HandleProcTriggerSpellAuraProc casts the trigger on the event's action
-- target). HitMask 0 keeps the default normal-or-critical behaviour. DisableEffectsMask 0 because
-- 704488 has a single effect and it is the proc effect. Chance is the record's own ProcChance (100).
-- Scope note: this row fixes only the "never applied" half of the issue. Mark of Order's own stack
-- growth is separately broken - 806270 "Add stack" carries its delta in MiscValueB while
-- Spell::EffectAscensionModifyAuraStacks reads MiscValue - and that repair belongs in the module's
-- SpellInfo contract pass, not in `spell_proc`.
DELETE FROM `spell_proc` WHERE `SpellId` = 704488;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(704488, 0, 28, 0, 4194304, 0, 16384, 2, 2, 0, 0, 0, 0, 100, 0, 0);
