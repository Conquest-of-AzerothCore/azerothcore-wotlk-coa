-- Agonizing Pain (680745): "Damage dealt by your Atherann's Anguish now causes enemies hit to bleed,
-- dealing ... Shadow damage over $680744d."
-- Its single effect is SPELL_AURA_PROC_TRIGGER_SPELL (aura 42) on Agonizing Pain 680744, a correct Shadow
-- bleed (aura 3 SPELL_AURA_PERIODIC_DAMAGE, BasePoints 280, DieSides 8, Amplitude 2000, Mechanic 15,
-- TargetA 6 = enemy), already registered for scaling in AscensionScalingBaseData.h. Spell.dbc gives 680745
-- ProcFlags 0 and no `spell_proc` row existed, so SpellMgr::LoadSpellProcs generated no entry
-- ("Skip if no proc flags in DBC"), SpellMgr::GetSpellProcEntry returned nullptr and
-- Aura::GetProcEffectMask returned 0: the aura was inert.
--
-- The event spell is Atherann's Anguish 680681, not the cast 680680/570146. Both castable records carry
-- SpellFamilyFlags (4096, 0, 0) but neither has a damage effect at all - their effects are aura 4 (dummy,
-- EffectTriggerSpell 680681), aura 69 SPELL_AURA_SCHOOL_ABSORB with MiscValueB 30/25 (the hemoplague
-- accumulator) and a second aura 4. The record that actually deals the Shadow damage is 680681
-- "Atherann's Anguish", a single SPELL_EFFECT_SCHOOL_DAMAGE (2) with SchoolMask 32 and DmgClass 1, and
-- Spell.dbc gives it SpellFamilyFlags (4, 0, 0) - a bit no other family-26 record carries. Hence
-- SpellFamilyName 26 with SpellFamilyMask0 4, and ProcFlags 65536
-- (PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG), the bit Spell::DoAllEffectOnTarget raises for a harmful
-- DmgClass 1 spell. SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE) for "damage dealt", SpellPhaseMask 2 (HIT),
-- HitMask 0 so the done-proc defaults NORMAL | CRITICAL | ABSORB apply - 680680 states that its damage
-- cannot critically strike, so restricting the hit mask would gain nothing.
-- AttributesMask 2 (PROC_ATTR_TRIGGERED_CAN_PROC) is required: 680681 is cast as a triggered spell and
-- carries neither SPELL_ATTR3_CAN_PROC_FROM_PROCS nor SPELL_ATTR3_NOT_A_PROC (its AttributesEx3 is
-- 0x40000000, SPELL_ATTR3_DO_NOT_DISPLAY_RANGE), so Aura::GetProcEffectMask would otherwise refuse the
-- event. No loop is possible: 680744 is a periodic bleed with no proc trigger of its own.
-- Chance 0 defers to the record's own ProcChance 100, per rev_20260919_20_coa_proc_chance_parity.sql.
DELETE FROM `spell_proc` WHERE `SpellId` = 680745;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680745, 0, 26, 4, 0, 0, 65536, 1, 2, 0, 2, 0, 0, 0, 0, 0);
