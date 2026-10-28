-- Infinite Power (92118): "Casting damaging spells now reduces your damaging spell cooldowns by
-- $528312s1% of their remaining cooldown." Effect 0 is aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL)
-- triggering 503946 (Empowerment Chaos CD refresh), but Spell.dbc gives 92118 ProcFlags 0 and no
-- spell_proc row existed, so SpellMgr::LoadSpellProcs skipped it and it never fired. 92118 carries no
-- SpellFamilyFlags of its own (it applies to "damaging spells" generically, not one ability), so the
-- row is unmasked, mirroring rev_20260922_06_stormbringer_storm_ascendance.sql's "your damaging spells"
-- clause (SpellFamilyName/masks 0, ProcFlags = NONE_DMG_CLASS_NEG | MAGIC_DMG_CLASS_NEG). Chronomancer's
-- own damaging spells span two DmgClass values (Melt Reality 806335, Unmake 804418 and Reverse Wound
-- 501805 are DmgClass 1 = magic; Wand of Time 520175 and Artificer's Wand's damaging sub-spell 561064
-- are DmgClass 3 = ranged), so PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS (0x100) is added to that precedent's
-- two flags to also admit the wand attacks: 4096 + 65536 + 256 = 69888. SpellTypeMask 1 = damage,
-- SpellPhaseMask 2 = hit, Chance 100 (the tooltip states no percentage), AttributesMask 2 =
-- PROC_ATTR_TRIGGERED_CAN_PROC so Artificer's Wand's triggered attack spell (561064) can still proc it,
-- matching the same attribute on the Storm Ascendance and Bieko Effect precedents.
--
-- 503946's own three effects are all the custom effect 192 (SPELL_EFFECT_ASCENSION_REDUCE_REMAINING_COOLDOWN_PCT,
-- left EffectNULL core-wide in SpellEffects.cpp), with EffectMiscValue 801291/801292/806335 (the spells to
-- discount) and EffectBasePoints 9 (+1 DieSides = 10%). This is the exact contract the reusable
-- spell_ascension_the_bieko_effect SpellScript (AscensionChronomancerTalents.cpp) already implements for
-- other effect-192 payloads; it is class-wide registered and only needs a spell_script_names row to attach
-- to 503946, not a new core-wide effect-192 handler.
DELETE FROM `spell_proc` WHERE `SpellId` = 92118;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(92118, 0, 0, 0, 0, 0, 69888, 1, 2, 0, 2, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 503946 AND `ScriptName` = 'spell_ascension_the_bieko_effect';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(503946, 'spell_ascension_the_bieko_effect');
