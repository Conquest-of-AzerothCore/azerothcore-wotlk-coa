-- Thorim's Gift (570173): "Your Arm of Thorim now leaves unstable electricity beneath the target, dealing
-- damage equal to $s1% of its damage dealt to enemies within every $570174t1 sec for $570174d." Its single
-- effect is SPELL_EFFECT_APPLY_AURA with aura 354, EffectBasePoints 14 + DieSides 1 = the 15% of $s1, and
-- TriggerSpell 570174 - a SPELL_EFFECT_PERSISTENT_AREA_AURA with SPELL_AURA_PERIODIC_DAMAGE, amplitude
-- 1000 ms, DurationIndex 27 (3000 ms), radius index 193 (6 yd), TargetA TARGET_DEST_TARGET_ENEMY and
-- EffectBasePoints -1 + DieSides 1 = 0, i.e. the per-tick amount has to be supplied by the caller.
-- Aura 354 is `nullptr` in AuraEffectHandler (SpellAuraEffects.cpp:419) and has no case in
-- AuraEffect::HandleProc, and 570173's own ProcFlags are 4 (PROC_FLAG_DONE_MELEE_AUTO_ATTACK), which a
-- Stormbringer's Arm of Thorim never raises, so Aura::GetProcEffectMask returned 0 and nothing ever reached
-- 570174. This row supplies the proc flags the record lacks; the forwarded amount comes from the script
-- aura_ascension_thorims_gift.
-- ProcFlags 65536 is PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG (SpellMgr.h:134), the flag raised for the
-- caster of a negative SPELL_DAMAGE_CLASS_MAGIC hit; every Arm of Thorim rank is DmgClass 1 with
-- SPELL_EFFECT_SCHOOL_DAMAGE on TARGET_UNIT_TARGET_ENEMY. SpellFamilyName 22 with SpellFamilyMask1 2
-- restricts the proc to Arm of Thorim: enumerating family 22 over Spell.dbc returns for that bit only its
-- ten records (801847 and 501433-501437 and 567518-567520 plus the chained 801848) and the three
-- Electrified Waters / Static Electricity helpers 573437, 573438 and 573451, which carry no damage effect
-- and so raise no damage proc. SpellTypeMask 1 is PROC_SPELL_TYPE_DAMAGE and SpellPhaseMask 2 is
-- PROC_SPELL_PHASE_HIT, which SpellMgr::CanSpellTriggerProcOnEvent requires for a DONE spell hit. HitMask 0
-- keeps the default done-proc set NORMAL | CRITICAL | ABSORB. SchoolMask 0 because the family mask already
-- names the ability. AttributesMask 0: Arm of Thorim is cast directly, never as a triggered spell.
-- Chance 100 is the record's own ProcChance, and the description states no internal cooldown, so
-- Cooldown and Charges stay 0. 570174 is periodic, so it cannot re-enter this direct-hit proc.
START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` = 570173;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(570173, 0, 22, 0, 2, 0, 65536, 1, 2, 0, 0, 0, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 570173 AND `ScriptName` = 'aura_ascension_thorims_gift';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(570173, 'aura_ascension_thorims_gift');
COMMIT;
