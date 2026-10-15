-- Blood Moon (707623): "While below 75% health, you now heal for $s1% of all damage you deal." Its single
-- effect is SPELL_EFFECT_APPLY_AURA with aura 354, BasePoints 2 + DieSides 1 = the 3% of $s1, and
-- TriggerSpell Blood Moon 572786 (SPELL_EFFECT_HEAL on the caster, BasePoints 0 - the amount has to be
-- supplied by the caller). Aura 354 has no entry in AuraEffectHandler, no case in AuraEffect::HandleProc
-- and is not an isTriggerAura; on top of that the record's own ProcFlags are 0, so SpellMgr's generator
-- skipped it twice over and Aura::GetProcEffectMask returned 0. The talent did nothing at all.
-- The 75% health gate is carried by the description text only - no Spell.dbc field of 707623 holds it
-- (CasterAuraState is 0) - so it lives in aura_ascension_bloodmage_blood_moon, not in this row.
-- 804199, the other spell the issue names, is an unrelated SPELLMOD_EFFECT1 on Animated Blood's summon
-- count and already works natively; it is not touched here.
-- ProcFlags 332116 = 4 + 16 + 64 + 256 + 4096 + 65536 (every "damage done" flag: melee and ranged auto
-- attacks and melee/ranged/none-negative/magic-negative spell damage) + 262144 (PROC_FLAG_DONE_PERIODIC),
-- because the tooltip says "all damage you deal" and a Bloodmage's damage is largely periodic.
-- SpellTypeMask 1 (damage) and SpellPhaseMask 2 (hit) keep it on real damage events. HitMask stays 0: a
-- DONE proc with no HitMask already defaults to NORMAL | CRITICAL | ABSORB, the usual damage-done set.
-- SpellFamilyName/masks are 0 because "all damage you deal" is not restricted to one ability.
-- Chance is the record's own ProcChance (100 - the tooltip states no percentage) and Charges stays 0.
DELETE FROM `spell_proc` WHERE `SpellId` = 707623;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(707623, 0, 0, 0, 0, 0, 332116, 1, 2, 0, 0, 0, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 707623 AND `ScriptName` = 'aura_ascension_bloodmage_blood_moon';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(707623, 'aura_ascension_bloodmage_blood_moon');
