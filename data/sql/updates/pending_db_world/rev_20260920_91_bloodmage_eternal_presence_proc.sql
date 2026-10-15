-- Eternal Presence (560001): "Increases the attack power of party and raid members by $s1%. Does not stack
-- with similar effects. / In addition, you now gain attack power equal to $s3% of the damage taken for
-- $560010d. Can only occur once every 10 sec." The first sentence already works: effects 0 and 1 are
-- SPELL_EFFECT_APPLY_AREA_AURA_RAID with auras 166/167 at 5%, and 560001 is already in spell_group 2000180,
-- whose same-effect aura types are hard-coded at SpellMgr.cpp:1866. Nothing below touches that half.
-- The second sentence never ran: effect 2 is the private aura 354, which is `nullptr` in AuraEffectHandler
-- (SpellAuraEffects.cpp:419) and has no core consumer, and Spell.dbc gives the record ProcFlags 0x0, so its
-- TriggerSpell 560010 was never cast. 560010's own single effect is a flat +5 attack power (aura 99), not a
-- share of anything, so the 15% of the damage taken is forwarded by aura_ascension_eternal_presence.
-- ProcFlags 1048576 is PROC_FLAG_TAKEN_DAMAGE (SpellMgr.h:140), "taken any damage", which is what "the
-- damage taken" means and which the melee, spell and periodic paths all raise (Unit.cpp:1979,
-- Spell.cpp:2909, SpellAuraEffects.cpp:6584). SchoolMask 0 and SpellFamilyName 0: the tooltip restricts the
-- source of the damage in no way, and SpellMgr::CanSpellTriggerProcOnEvent only applies the family test to
-- SPELL_PROC_FLAG_MASK events anyway. SpellTypeMask 0 and SpellPhaseMask 0 are likewise unread for a
-- TAKEN_DAMAGE event (the type check is gated on SPELL_PROC_FLAG_MASK | PERIODIC_PROC_FLAG_MASK and the
-- phase check on REQ_SPELL_PHASE_PROC_FLAG_MASK, which holds DONE flags only). HitMask 0 keeps the default
-- taken-proc set NORMAL | CRITICAL. AttributesMask 2 is PROC_ATTR_TRIGGERED_CAN_PROC, so damage delivered by
-- a triggered spell still counts as damage taken. Chance 100: the record's ProcChance 101 is the passive
-- sentinel and the tooltip states no percentage. Cooldown 10000 is the "once every 10 sec" the tooltip
-- states, matching 560010's own DurationIndex 1 (10 000 ms).
START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` = 560001;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560001, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 2, 0, 0, 100, 10000, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 560001 AND `ScriptName` = 'aura_ascension_eternal_presence';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(560001, 'aura_ascension_eternal_presence');
COMMIT;
