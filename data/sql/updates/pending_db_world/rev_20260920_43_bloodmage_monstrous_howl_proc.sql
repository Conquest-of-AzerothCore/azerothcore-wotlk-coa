-- Monstrous Howl (804811): "Enrage for $d, causing the next 6 Bloodfang Bites to have a $s1% reduced
-- global cooldown and cost and to trigger Call of the Darkwing." Effects 0 and 1 are aura 108
-- (SPELL_AURA_ADD_PCT_MODIFIER) with MiscValue 21 (SPELLMOD_GLOBAL_COOLDOWN) and 14 (SPELLMOD_COST),
-- BasePoints -51 -> -50%, EffectSpellClassMask (0, 8388608, 0); both already work through the generic
-- spellmod path and are untouched here. Effect 2 is aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL) on Call of the
-- Darkwing 801958 (a stock SPELL_EFFECT_SUMMON, MiscValue 50069, DieSides 2, TargetA 22 = a destination
-- around the caster, so it needs no unit target), but Spell.dbc gives 804811 ProcFlags 0 and no
-- `spell_proc` row existed, so SpellMgr::LoadSpellProcs skipped the record and the summon clause never
-- fired. Same reasoning and shape as rev_20260918_32_bloodmage_council_assembled_proc.
--
-- Proc source is Bloodfang Bite: ranks 501695-501697, 503613-503615, 572549-572551 and 800156 all carry
-- SpellFamilyFlags (0, 8388608, 0) and DmgClass MELEE, and no other family-26 record carries that flag -
-- the same mask the two spellmod effects already use. `ProcFlags` 16 is DONE_SPELL_MELEE_DMG_CLASS, the
-- flag Spell::PrepareDataForTriggerSystem raises for a DmgClass MELEE ability.
-- `SpellPhaseMask` 1 (PROC_SPELL_PHASE_CAST) matches the two spellmod clauses, which are consumed when the
-- bite is cast, so a bite that misses still spends its charge consistently for all three clauses.
-- `HitMask` stays 0: at CAST phase with DONE flags the core skips the hit check unless HitMask is set.
--
-- `Charges` 6 is the decisive column. The tooltip says "the next 6 Bloodfang Bites" but Spell.dbc gives
-- 804811 ProcCharges 0, and Aura::CalcMaxCharges takes its value from the `spell_proc` entry whenever one
-- exists, so without an explicit 6 the buff would never expire on use. Charges are dropped once per proc
-- by the proc system, not twice by the two spellmods: Player::RemoveSpellMods skips every modifier whose
-- spell has a `spell_proc` entry ("don't handle spells with spell_proc entry defined").
--
-- `Chance` is the record's own ProcChance (100). AttributesMask is 0 (PROC_ATTR_TRIGGERED_CAN_PROC not
-- set): Bloodfang Bite is cast directly by the player and no helper spell casts it as a triggered effect.
-- SchoolMask and SpellTypeMask are 0 (the tooltip restricts neither).
DELETE FROM `spell_proc` WHERE `SpellId` = 804811;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(804811, 0, 26, 0, 8388608, 0, 16, 0, 1, 0, 0, 0, 0, 100, 0, 6);
