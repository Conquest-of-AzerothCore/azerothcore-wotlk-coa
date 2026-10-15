-- Infection (704624): "Auto attacking a bleeding target will now infect the wound, increasing their chance
-- to be critically struck from you by $707867s1% for $707867d, stacking $707867u times." Effect 0 is aura
-- 42 (SPELL_AURA_PROC_TRIGGER_SPELL) on Infection 707867, which is well-formed: aura 308
-- (SPELL_AURA_MOD_CRIT_CHANCE_FOR_CASTER, native at SpellAuraEffects.cpp and caster-GUID gated, matching
-- "from you"), BasePoints 0 -> +1%, StackAmount 10, duration index 32, TargetA 6. But Spell.dbc gives
-- 704624 ProcFlags 0 and no `spell_proc` row existed, so SpellMgr::LoadSpellProcs skipped the record
-- ("Skip if no proc flags in DBC") and Aura::GetProcEffectMask returned a zero mask: the aura could never
-- fire. Same reasoning and shape as rev_20260918_32_bloodmage_council_assembled_proc.
--
-- `ProcFlags` 4 is PROC_FLAG_DONE_MELEE_AUTO_ATTACK alone - the tooltip says "auto attacking" and names no
-- ability. `SpellPhaseMask` is 0 because that flag is outside REQ_SPELL_PHASE_PROC_FLAG_MASK, so a phase
-- would be dead data (same convention as rev_20260908_08_class_completion_runtime).
-- `SpellFamilyName`/`SpellFamilyMask`/`SchoolMask`/`SpellTypeMask` are 0: an auto attack carries no spell
-- family. `HitMask` stays 0, which for a DONE proc defaults to NORMAL | CRITICAL | ABSORB - every swing
-- that actually connects. `Chance` is the record's own ProcChance (100). AttributesMask is 0
-- (PROC_ATTR_TRIGGERED_CAN_PROC not set): an auto attack is never a triggered spell.
--
-- The tooltip's "a bleeding target" gate has no `spell_proc` column, so it is enforced in a CheckProc
-- handler: aura_ascension_bloodmage_infection in
-- modules/mod-ascension-compat/src/AscensionBloodmageProcs.cpp requires the action target to carry an
-- aura with MECHANIC_BLEED (Unit::HasAuraWithMechanic). Without that script this row would infect every
-- target on every swing, so the two changes belong together.
DELETE FROM `spell_proc` WHERE `SpellId` = 704624;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(704624, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 704624 AND `ScriptName` = 'aura_ascension_bloodmage_infection';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(704624, 'aura_ascension_bloodmage_infection');
