-- Unmaker of Realities (706107): "While Hasten is active the ally now has a $803382h% chance when they
-- deal damage to strike the target an additional time equal to $803382s1% of the damage dealt."
-- The talent's own record is a single SPELL_AURA_DUMMY (aura 4) with no script anywhere in src/ or
-- modules/, so it does nothing by itself. The two numbers the tooltip interpolates come from Hasten
-- variant 803382 (ProcChance 25; Effect[0] EffectBasePoints 29, die 1 => CalcValue 30), which is not
-- obtainable (advancement=none, live_capture=False) and whose aura 354 has no handler in this core
-- (SpellAuraEffects.cpp: `nullptr, //354 unknown Ascension aura`). The Hasten players actually learn is
-- 801304 (AscensionCustomClassData.h {22, 36, 801304}); its three effects are auras 31/192/216 and carry
-- no proc effect at all, so the extra strike has to be attached to 801304.
-- spell_ascension_unmaker_of_realities hangs the mechanic on 801304: CheckProc requires the buff's
-- caster to know 706107, and the proc forwards 30% of the damage dealt into Hasty Strike 803706
-- (SPELL_EFFECT_SCHOOL_DAMAGE, EffectBasePoints 1, die 1, SPELL_ATTR2_CANT_CRIT +
-- SPELL_ATTR3_IGNORE_CASTER_MODIFIERS + SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS - a pure forwarding
-- stub). Without a `spell_proc` row the AuraScript's hooks are never reached: SpellMgr.cpp's generation
-- pass skips records with ProcFlags 0 (801304 has 0x0) and Aura::GetProcEffectMask returns 0 when there
-- is no proc entry.
-- ProcFlags 69972 = 0x4 DONE_MELEE_AUTO_ATTACK | 0x10 DONE_SPELL_MELEE_DMG_CLASS |
-- 0x40 DONE_RANGED_AUTO_ATTACK | 0x100 DONE_SPELL_RANGED_DMG_CLASS | 0x1000 DONE_SPELL_NONE_DMG_CLASS_NEG
-- | 0x10000 DONE_SPELL_MAGIC_DMG_CLASS_NEG - every way the buff holder can land a direct damaging hit.
-- PROC_FLAG_DONE_PERIODIC (0x40000) is deliberately excluded: the tooltip promises an extra *strike*,
-- and a per-tick extra strike would multiply the effect across every damage-over-time the ally runs.
-- SpellFamilyName 0 (no family/flag restriction - the tooltip says "when they deal damage", not "when
-- they cast X"), SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE: the forwarded amount has to exist),
-- SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT - melee auto attacks are outside REQ_SPELL_PHASE_PROC_FLAG_MASK
-- and are unaffected by it), Chance 25 from 803382's own ProcChance, and AttributesMask 0 so
-- PROC_ATTR_TRIGGERED_CAN_PROC stays off and Hasty Strike cannot chain off itself.
DELETE FROM `spell_script_names` WHERE `spell_id` = 801304 AND `ScriptName` = 'spell_ascension_unmaker_of_realities';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(801304, 'spell_ascension_unmaker_of_realities');
DELETE FROM `spell_proc` WHERE `SpellId` = 801304;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(801304, 0, 0, 0, 0, 0, 69972, 1, 2, 0, 0, 0, 0, 25, 0, 0);
