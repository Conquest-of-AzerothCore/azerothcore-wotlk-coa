-- Waves of Blood (681427): "Each tick of Crimson Tide now has a $681427h% chance to heal a nearby ally for
-- $681427s1% of the damage dealt." Its single effect is the private aura 354, which is `nullptr` in
-- AuraEffectHandler (SpellAuraEffects.cpp:419) and has no core consumer, and Spell.dbc gives the record
-- ProcFlags 0x0, so nothing ever reached its TriggerSpell 807652 - a real SPELL_EFFECT_HEAL with
-- TargetA 18 / TargetB 31, radius index 23 (40 yd) and MaxAffectedTargets 1, i.e. "a nearby ally". This row
-- supplies the proc flags the record lacks; the forwarded amount comes from the script
-- aura_ascension_waves_of_blood, because 807652 ships BasePoints 0 and EffectBonusMultiplier 0.
-- ProcFlags 262144 is PROC_FLAG_DONE_PERIODIC (SpellMgr.h:140), the flag AuraEffect::
-- HandlePeriodicDamageAurasTick raises for the caster of a damaging tick (SpellAuraEffects.cpp:6575).
-- SpellFamilyName 26 with SpellFamilyMask0 16384 restricts the proc to Crimson Tide: enumerating family 26
-- over Spell.dbc returns exactly its nine ranks (504282 lvl 27 and 504129-504136) for that bit and nothing
-- else. SpellTypeMask 1 is PROC_SPELL_TYPE_DAMAGE (the tooltip says "each tick ... of the damage dealt", so
-- only damaging ticks count); SpellPhaseMask 2 is PROC_SPELL_PHASE_HIT, which SpellMgr::
-- CanSpellTriggerProcOnEvent requires for a DONE periodic event. HitMask 0 keeps the default done-proc set
-- NORMAL | CRITICAL | ABSORB. AttributesMask 0: no helper casts Crimson Tide as a triggered spell.
-- Chance 10 is the record's own ProcChance, which is what the tooltip renders as $681427h; Cooldown 0
-- because the description states no internal cooldown.
START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` = 681427;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(681427, 0, 26, 16384, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 10, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 681427 AND `ScriptName` = 'aura_ascension_waves_of_blood';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(681427, 'aura_ascension_waves_of_blood');
COMMIT;
