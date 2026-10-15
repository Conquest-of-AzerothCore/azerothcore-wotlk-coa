-- Excess Blood (504100) and Crimson Scion (806424): two Bloodmage healing passives whose single effect is
-- SPELL_AURA_PROC_TRIGGER_SPELL (aura 42) with Spell.dbc ProcFlags 0 and no `spell_proc` row, so
-- SpellMgr::LoadSpellProcs generated no entry ("Skip if no proc flags in DBC"),
-- SpellMgr::GetSpellProcEntry returned nullptr and Aura::GetProcEffectMask returned 0.
-- Both leave Chance 0 so the record's own ProcChance (10 for each) is used, the convention of
-- rev_20260919_20_coa_proc_chance_parity.sql, and AttributesMask 0 because neither trigger is itself a
-- triggered spell of some other record.
--
-- Excess Blood (504100): "Your healing done now has a $h% chance to heal the target for an additional ...
-- over $504101d." Trigger 504101 is a correct native HoT: aura 8 SPELL_AURA_PERIODIC_HEAL, BasePoints 79,
-- Amplitude 1500, DurationIndex 32, TargetA 21, already registered for scaling in
-- AscensionScalingBaseData.h. ProcFlags 16896 = PROC_FLAG_DONE_SPELL_NONE_DMG_CLASS_POS (0x400) |
-- PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_POS (0x4000): the two "positive spell done" directions, magic for
-- the Bloodmage's own heals (Sanguine Mend is DmgClass 1) and none-damage-class for the rest. The periodic
-- flags stay out - the tooltip says "your healing done", the act of healing, and the trigger is itself a
-- HoT, so including PROC_FLAG_DONE_PERIODIC would let it feed itself. SpellTypeMask 2
-- (PROC_SPELL_TYPE_HEAL), SpellPhaseMask 2 (HIT), HitMask 0 (defaults). No script is needed for targeting:
-- AuraEffect::HandleProcTriggerSpellAuraProc casts the trigger at eventInfo.GetActionTarget(), the unit
-- just healed, matching "heal the target".
--
-- Crimson Scion (806424): "Direct damage dealt now has a $h% chance to make your next Sanguine Mend within
-- $806425d instant cast." Trigger 806425 is native: aura 108 SPELL_AURA_ADD_PCT_MODIFIER, MiscValue 10
-- (SPELLMOD_CASTING_TIME), BasePoints -101 (-100%, i.e. instant), EffectSpellClassMask (524288, 0, 0) =
-- the nine Sanguine Mend ranks. ProcFlags 69908 = PROC_FLAG_DONE_MELEE_AUTO_ATTACK (0x4) |
-- PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS (0x10) | PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS (0x100) |
-- PROC_FLAG_DONE_SPELL_NONE_DMG_CLASS_NEG (0x1000) | PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG (0x10000):
-- "damage dealt" without qualification, minus the periodic flags because the tooltip says "direct".
-- SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE), SpellPhaseMask 2 (HIT), HitMask 0 (defaults).
-- 806425's Description field ("Generates $s1% of your Maximum Rage") contradicts its own AuraDescription
-- and its single effect; it is client-side text and is not touched here.
DELETE FROM `spell_proc` WHERE `SpellId` IN (504100, 806424);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504100, 0, 0, 0, 0, 0, 16896, 2, 2, 0, 0, 0, 0, 0, 0, 0),
(806424, 0, 0, 0, 0, 0, 69908, 1, 2, 0, 0, 0, 0, 0, 0, 0);
