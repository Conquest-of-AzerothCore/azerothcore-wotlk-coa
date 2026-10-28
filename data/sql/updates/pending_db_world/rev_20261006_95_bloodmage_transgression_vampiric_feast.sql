-- Transgression (801076): "Enter a unique Cursed Form for $d that does not disable the use of Mortal Form
-- abilities. While active, direct spell damage triggers a Vampiric Feast, dealing $801076s3% additional
-- Shadow damage to enemies, healing you equal to 50% of the damage dealt." The Mortal Form half works (the
-- form is listed in AscensionBloodmageTalents' MortalAbilityForms), but the Vampiric Feast half did nothing.
-- Effect 3 of 801076 (EFFECT_2) is SPELL_EFFECT_APPLY_AURA with aura 354, BasePoints 19 + DieSides 1 =
-- the 20% $801076s3 renders, and TriggerSpell Vampiric Feast 804934 (SPELL_EFFECT_HEALTH_LEECH, BasePoints
-- 0 - the amount has to be supplied by the caller - EffectValueMultiplier 0.5 = the "50% of the damage
-- dealt" heal, SchoolMask 32 Shadow). Aura 354 has no entry in AuraEffectHandler, no case in
-- AuraEffect::HandleProc and is not an isTriggerAura, and 801076 carries ProcFlags 0 in Spell.dbc, so
-- SpellMgr::LoadSpellProcs generated no entry for it and Aura::GetProcEffectMask returned 0: the clause
-- was never implemented. Same shape as Blood Moon 707623, Cursed Blood 707435 and Sanguine Essence 680692.
-- ProcFlags 69904 = 16 + 256 + 4096 + 65536: every "negative spell that deals damage" done flag (melee,
-- ranged, none and magic damage class) and nothing else. The tooltip asks for "direct spell damage", so
-- PROC_FLAG_DONE_PERIODIC (262144) and the melee/ranged auto attacks (4 and 64) stay out: a Bloodmage's
-- damage is largely periodic and neither of those is a spell.
-- SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE) and SpellPhaseMask 2 (HIT) keep it on real damage events.
-- HitMask stays 0: a DONE proc with no HitMask already defaults to NORMAL | CRITICAL | ABSORB, so an
-- ordinary and a critical hit both trigger the Feast. SpellFamilyName and its masks stay 0 because the
-- tooltip says "direct spell damage" without naming an ability.
-- DisableEffectsMask 3 turns off the two Mortal Form bookkeeping effects (both aura 4) and leaves the
-- aura-354 effect enabled, which is the one Aura::GetProcEffectMask then hands to
-- aura_ascension_bloodmage_transgression. Chance is the record's own ProcChance (100 - the tooltip states
-- no percentage); Charges and Cooldown stay 0, so nothing limits the trigger beyond the global cooldown.
DELETE FROM `spell_proc` WHERE `SpellId` = 801076;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(801076, 0, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 3, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 801076 AND `ScriptName` = 'aura_ascension_bloodmage_transgression';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(801076, 'aura_ascension_bloodmage_transgression');
