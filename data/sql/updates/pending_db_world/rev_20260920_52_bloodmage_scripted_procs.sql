-- Essence Harvester (806421) and Blood Bond (504627): two Bloodmage abilities whose
-- SPELL_AURA_PROC_TRIGGER_SPELL (aura 42) effect carries a condition that no `spell_proc` column can
-- express, so each gets a row plus an AuraScript in
-- modules/mod-ascension-compat/src/AscensionBloodmageTalents.cpp. Both records have Spell.dbc ProcFlags 0
-- and had no row, so SpellMgr::LoadSpellProcs generated no entry ("Skip if no proc flags in DBC"),
-- SpellMgr::GetSpellProcEntry returned nullptr and Aura::GetProcEffectMask returned 0.
--
-- Essence Harvester (806421): "Being struck by an enemy while below 35% health instantly resets the
-- cooldown of your Vampiric Fang and grants you Wretched. Can only occur once per minute."
-- Its single effect is aura 42 on Wretched 504284, which is complete on its own: aura 23
-- SPELL_AURA_PERIODIC_TRIGGER_SPELL on 504283 every 1000 ms (the Rage and Thirst income) plus
-- SPELL_EFFECT_ASCENSION_RESET_COOLDOWN (195) with MiscValue 804726 = Vampiric Fang and MiscValueB 1, so
-- the cooldown reset is already in the data and no code recreates it. Both of 504284's effects use
-- TargetA 1 (caster), and AuraEffect::HandleProcTriggerSpellAuraProc uses aurApp->GetTarget() - the
-- Bloodmage - as the trigger caster, so the buff lands on the right unit without a script.
-- ProcFlags 1048576 = PROC_FLAG_TAKEN_DAMAGE, "being struck by an enemy" in its broadest form: it covers
-- melee, ranged and spell damage in one bit and is outside SPELL_PROC_FLAG_MASK and
-- REQ_SPELL_PHASE_PROC_FLAG_MASK, which is why SpellTypeMask and SpellPhaseMask stay 0 -
-- SpellMgr::CanSpellTriggerProcOnEvent never consults them for this event, and LoadSpellProcs warns when
-- they are set but unusable. HitMask 0 leaves the taken-proc default NORMAL | CRITICAL.
-- Cooldown 60000 is the tooltip's "once per minute". Chance 0 defers to the record's own ProcChance 100.
-- The "while below 35% health" gate is the AuraScript's DoCheckProc; there is no column for it.
--
-- Blood Bond (504627): "causing direct damage taken by the ally to generate $/10;505325s1 Rage and
-- ${$505325m2+$505325ppl2}% base health". Effect 0 is aura 42 on Blood Bond 505325
-- (SPELL_EFFECT_ENERGIZE, MiscValue 1 = Rage, BasePoints 9, plus
-- SPELL_EFFECT_ASCENSION_RESTORE_BASE_HEALTH_PCT (181) BasePoints 2, both TargetA 1 = caster) and its own
-- TargetA is 57, so the aura is applied to the bonded ally, not to the Bloodmage. The default proc path
-- would therefore energize the ally; the AuraScript redirects the cast to the aura's caster, which is the
-- only reason a script is needed for this half.
-- ProcFlags 139944 = PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK (0x8) | PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS
-- (0x20) | PROC_FLAG_TAKEN_RANGED_AUTO_ATTACK (0x80) | PROC_FLAG_TAKEN_SPELL_RANGED_DMG_CLASS (0x200)
-- | PROC_FLAG_TAKEN_SPELL_NONE_DMG_CLASS_NEG (0x2000) | PROC_FLAG_TAKEN_SPELL_MAGIC_DMG_CLASS_NEG
-- (0x20000). PROC_FLAG_TAKEN_PERIODIC and PROC_FLAG_TAKEN_DAMAGE are deliberately left out: the tooltip
-- says "direct damage taken", and PROC_FLAG_TAKEN_DAMAGE would also fire on damage-over-time ticks.
-- SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE), SpellPhaseMask 0 - taken flags are outside
-- REQ_SPELL_PHASE_PROC_FLAG_MASK, so LoadSpellProcs would warn about a phase mask it cannot use -
-- HitMask 0 (taken default NORMAL | CRITICAL), Chance 0 for the record's own ProcChance 100.
-- Effect 1 of 504627 (aura 23 on 505169, the out-of-combat movement speed) is native and untouched, and
-- DisableEffectsMask stays 0 because effect 1 is not a trigger aura and cannot proc.
--
-- Not covered here: 504627's tooltip also promises to "redirect $s3% of their threat generated to you",
-- but the record has only two effects and no third slot carries it, so that clause has no data path at all.
START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` IN (806421, 504627);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(806421, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 60000, 0),
(504627, 0, 0, 0, 0, 0, 139944, 1, 0, 0, 0, 0, 0, 0, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` IN (806421, 504627)
  AND `ScriptName` IN ('aura_ascension_bloodmage_essence_harvester', 'aura_ascension_bloodmage_blood_bond');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(806421, 'aura_ascension_bloodmage_essence_harvester'),
(504627, 'aura_ascension_bloodmage_blood_bond');
COMMIT;
