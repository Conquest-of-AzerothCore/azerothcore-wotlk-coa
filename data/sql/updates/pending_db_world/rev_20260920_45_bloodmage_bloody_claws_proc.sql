-- Bloody Claws (572800): "You now generate $s1% increased Rage from damage dealt and critical strikes with
-- auto attacks now reduces the cooldown of Animated Blood, Blood Veil, and Blood Pact by 1 sec."
-- Effect 0 (aura 213 SPELL_AURA_MOD_RAGE_FROM_DAMAGE_DEALT, BasePoints 19 -> +20%) is the first clause and
-- already works natively through Player::RewardRage; it is untouched here. Effect 1 is aura 42
-- (SPELL_AURA_PROC_TRIGGER_SPELL) on Blood Claws 572912, which is exactly the second clause: three
-- SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN effects with BasePoints -1001 (-1000 ms) and MiscValue 801955
-- (Blood Pact), 573299 (Animated Blood) and 504263 (Blood Veil), all TargetA 1 = caster. But Spell.dbc
-- gives 572800 ProcFlags 0 and no `spell_proc` row existed, so SpellMgr::LoadSpellProcs skipped the record
-- ("Skip if no proc flags in DBC") and Aura::GetProcEffectMask returned a zero mask: the cooldown clause
-- could never fire. Same reasoning and shape as rev_20260918_32_bloodmage_council_assembled_proc.
-- (The two `data/sql/` hits for 572800 reported by a plain grep are coincidental digit substrings inside
-- gameobject.sql and pool_gameobject.sql, not a `spell_proc` row. 572912's own ProcChance 1 is irrelevant:
-- it is the triggered spell, not the proc source.)
--
-- `ProcFlags` 4 is PROC_FLAG_DONE_MELEE_AUTO_ATTACK alone - the tooltip says "auto attacks", so no spell
-- class flag belongs here. `HitMask` 2 is PROC_HIT_CRITICAL, the tooltip's "critical strikes"; an unset
-- HitMask on a DONE proc would default to NORMAL | CRITICAL | ABSORB and fire on ordinary swings.
-- `SpellPhaseMask` is 0: PROC_FLAG_DONE_MELEE_AUTO_ATTACK is outside REQ_SPELL_PHASE_PROC_FLAG_MASK, so a
-- phase would be dead data (same convention as rev_20260908_08_class_completion_runtime).
-- `SpellFamilyName`/`SpellFamilyMask`/`SchoolMask`/`SpellTypeMask` are 0: an auto attack carries no spell
-- family and the tooltip restricts neither school nor spell type. `Chance` is the record's own ProcChance
-- (100). AttributesMask is 0 (PROC_ATTR_TRIGGERED_CAN_PROC not set): an auto attack is never a triggered
-- spell. `DisableEffectsMask` is 0: AuraEffect::HandleProc has no case for aura 213, so effect 0 cannot
-- trigger anything even while it is part of the proc mask.
DELETE FROM `spell_proc` WHERE `SpellId` = 572800;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(572800, 0, 0, 0, 0, 0, 4, 0, 0, 2, 0, 0, 0, 100, 0, 0);
