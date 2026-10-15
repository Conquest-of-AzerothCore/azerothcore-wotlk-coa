-- Cursed Blood (707435): "Damage dealt by Taldaram's Torment now has a $h% chance to internally rupture,
-- causing it to deal its damage an additional time to all enemies near the target." Its single effect is
-- SPELL_EFFECT_APPLY_AURA with aura 354, BasePoints 99 + DieSides 1 = 100 (the whole hit, "an additional
-- time"), and TriggerSpell Cursed Blood 707708 (SPELL_EFFECT_SCHOOL_DAMAGE, BasePoints 0, TargetA 6 plus
-- TargetB 16 over radius index 8 = 5 yards - the amount has to be supplied by the caller). Aura 354 has no
-- entry in AuraEffectHandler, no case in AuraEffect::HandleProc and is not an isTriggerAura; the record's
-- own ProcFlags are 0 as well, so no SpellProcEntry was ever generated and the talent did nothing.
-- ProcFlags 262144 is PROC_FLAG_DONE_PERIODIC alone: every Taldaram's Torment rank (800772, 802568-802573,
-- 802580) is a bleed - effect 0 is SPELL_EFFECT_APPLY_AURA with aura 3 SPELL_AURA_PERIODIC_DAMAGE at a
-- 3000 ms amplitude, and none of the eight ranks has a direct damage effect - so "damage dealt by
-- Taldaram's Torment" is periodic damage and only periodic ticks may rupture.
-- Proc restricted to Taldaram's Torment by SpellFamilyName 26 with SpellFamilyMask2 2097152: those eight
-- ranks are the only family-26 records carrying SpellFamilyFlags (0, 0, 2097152) in Spell.dbc, no
-- remainder. The effect's own ClassMask is (0, 0, 0), so the restriction has to come from this row.
-- SpellTypeMask 1 (damage) and SpellPhaseMask 2 (hit) match the phase AuraEffect::PeriodicTick procs on.
-- HitMask stays 0: a DONE proc with no HitMask defaults to NORMAL | CRITICAL | ABSORB, so an ordinary and
-- a critical tick may both rupture, which is what "damage dealt" says.
-- Chance is 20, the record's own ProcChance and the $h the description renders. 707708 carries a separate
-- ProcChance of 33 that matches no tooltip text and is deliberately not used.
DELETE FROM `spell_proc` WHERE `SpellId` = 707435;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(707435, 0, 26, 0, 0, 2097152, 262144, 1, 2, 0, 0, 0, 0, 20, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 707435 AND `ScriptName` = 'aura_ascension_bloodmage_cursed_blood';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(707435, 'aura_ascension_bloodmage_cursed_blood');
