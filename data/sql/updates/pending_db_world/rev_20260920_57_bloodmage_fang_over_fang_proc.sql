-- Fang Over Fang (504116): "Casting Bloodfang Bite now has a $h% chance to reset the cooldown of Reave."
-- Its single effect is SPELL_AURA_PROC_TRIGGER_SPELL (aura 42) on Fang Over Fang 504117, a single
-- SPELL_EFFECT_ASCENSION_RESET_COOLDOWN (195) with MiscValue 800490 = Reave (the same constant
-- AscensionBloodmageSecondary.cpp names SPELL_REAVE) and MiscValueB 1, which
-- Spell::EffectAscensionResetCooldown turns into RemoveSpellCooldown(800490) plus
-- RemoveCategoryCooldown on Reave's category. Spell.dbc gives 504116 ProcFlags 0 and no `spell_proc` row
-- existed, so SpellMgr::LoadSpellProcs generated no entry ("Skip if no proc flags in DBC"),
-- SpellMgr::GetSpellProcEntry returned nullptr and Aura::GetProcEffectMask returned 0: the aura was inert.
-- Reave's cooldown is entirely a category cooldown - every rank (800490, 802463-802469) has
-- RecoveryTime 0, Category 752 and CategoryRecoveryTime 15000 - so MiscValueB 1 is what makes the reset
-- reach the rank the character actually owns, not only rank 1.
-- The row is scoped to Bloodfang Bite by SpellFamilyName 26 and SpellFamilyMask1 8388608, the
-- SpellFamilyFlags (0, 8388608, 0) that Spell.dbc gives all ten Bloodfang Bite ranks (501695-501697,
-- 503613-503615, 572549-572551, 800156). One other family-26 record shares that bit, Crimson Maw 803388,
-- and no finer bit exists to separate them.
-- ProcFlags 16 = PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS, which is what Spell::PrepareDataForTriggerSystem
-- sets for a DmgClass 2 record such as Bloodfang Bite. SpellPhaseMask 1 (PROC_SPELL_PHASE_CAST) because the
-- tooltip says "Casting", not "hitting": Spell::cast raises the cast-phase event before the hit, and
-- SpellMgr::CanSpellTriggerProcOnEvent skips the hit-mask check for a DONE proc at the cast phase when
-- HitMask is unset, which is why HitMask stays 0. SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE) is safe at that
-- phase: Unit::ProcSkillsAndAuras reports PROC_SPELL_TYPE_MASK_ALL for PROC_SPELL_PHASE_CAST, since no
-- damage or heal has happened yet. Chance 0 defers to the record's own ProcChance 20, per
-- rev_20260919_20_coa_proc_chance_parity.sql. AttributesMask 0: Bloodfang Bite is a player cast.
DELETE FROM `spell_proc` WHERE `SpellId` = 504116;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504116, 0, 26, 0, 8388608, 0, 16, 1, 1, 0, 0, 0, 0, 0, 0, 0);
