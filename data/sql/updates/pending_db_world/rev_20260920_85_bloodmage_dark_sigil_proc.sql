-- Dark Sigil (560535): "Increases critical strike chance of all party and raid members by $s1%. Does not
-- stack with similar effects. In addition, you now heal for $s2% of all critical damage dealt." Effect 0
-- (SPELL_EFFECT_APPLY_AREA_AURA_RAID, aura 290 SPELL_AURA_MOD_CRIT_PCT, BasePoints 2 + DieSides 1 = 3%)
-- already works natively through AuraEffect::HandleAuraModCritPct and is untouched here. Effect 1 is
-- SPELL_EFFECT_APPLY_AURA with aura 354, BasePoints 14 + DieSides 1 = the 15% of $s2, and TriggerSpell
-- Bloodlord's Curse 707449 (SPELL_EFFECT_HEAL, BasePoints 0 - the amount has to be supplied by the caller).
-- Aura 354 has no entry in AuraEffectHandler, no case in AuraEffect::HandleProc and is not an
-- isTriggerAura, so no SpellProcEntry was generated and Aura::GetProcEffectMask returned 0: the leech half
-- never fired. This row plus aura_ascension_bloodmage_dark_sigil is the same pairing Hammer of Life
-- (rev_20260916_72) uses for its own aura-354 effect.
-- ProcFlags 332116 = 4 + 16 + 64 + 256 + 4096 + 65536 (every "damage done" flag: melee and ranged auto
-- attacks and melee/ranged/none-negative/magic-negative spell damage) + 262144 (PROC_FLAG_DONE_PERIODIC).
-- The record's own ProcFlags are 0x14, melee auto attacks and melee-class spells only, which would leave
-- this talent inert on a caster class; the tooltip says "all critical damage dealt", so the full
-- done-damage set including periodic critical ticks is used instead.
-- HitMask 2 is PROC_HIT_CRITICAL: only critical damage heals, exactly as the tooltip states.
-- SpellTypeMask 1 (damage) and SpellPhaseMask 2 (hit) keep it on real damage events.
-- DisableEffectsMask 1 excludes effect 0, the raid crit aura, from the proc - only effect 1 triggers.
-- SpellFamilyName/masks are 0 because "all critical damage" is not restricted to one ability.
-- Chance is the record's own ProcChance (100), and Charges stays 0 (ProcCharges 0 - the aura is permanent).
DELETE FROM `spell_proc` WHERE `SpellId` = 560535;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560535, 0, 0, 0, 0, 0, 332116, 1, 2, 2, 0, 1, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 560535 AND `ScriptName` = 'aura_ascension_bloodmage_dark_sigil';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(560535, 'aura_ascension_bloodmage_dark_sigil');
