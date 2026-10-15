-- Aeon Rend (583248): "Your Chromatic Shard now has a $h% chance to strike again and incur no cooldown."
-- $h renders the record's own ProcChance, which Spell.dbc gives as 25. Both halves of the talent are
-- already implemented: effect 0 is aura 42 (proc trigger spell) on Chromatic Shard 801292 itself (the
-- "strike again" half) and effect 1 is aura 42 on 583247, whose single effect is 195
-- (SPELL_EFFECT_ASCENSION_RESET_COOLDOWN, src/server/game/Spells/SpellEffects.cpp) with MiscValue 801292
-- (the "incur no cooldown" half). Spell.dbc gives 583248 ProcFlags 0, and SpellMgr::LoadSpellProcs skips
-- generating an entry for a record without proc flags, so Aura::GetProcEffectMask returned 0 for every
-- event and neither half ever fired. One roll per event drives both effects (Aura::GetProcEffectMask
-- rolls Chance once and returns the whole effect mask), which is what the tooltip describes.
-- Columns, all read from Spell.dbc this session:
--   SpellFamilyName 28 / SpellFamilyMask1 4096 / SpellFamilyMask2 33554432 - Chromatic Shard 801292's own
--     SpellFamilyName and SpellFamilyFlags, so only the ability the tooltip names can trigger it.
--   ProcFlags 65536 (PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG) - 801292 has DmgClass 1 (MAGIC) and is a
--     harmful spell, the case Spell.cpp fills in for a negative magic-class hit.
--   SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE) - 801292's effect 0 is SPELL_EFFECT_SCHOOL_DAMAGE, so
--     Unit::ProcSkillsAndAuras sees a non-zero DamageInfo at the HIT phase and computes DAMAGE, not the
--     NO_DMG_HEAL of an aura-only spell.
--   SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT) - the re-strike and the cooldown reset follow a landed hit.
--   HitMask 0 - default NORMAL|CRITICAL|ABSORB for a DONE proc; the tooltip makes no hit-result claim.
--   AttributesMask 0 - deliberately no PROC_ATTR_TRIGGERED_CAN_PROC, so the re-struck (triggered) 801292
--     cannot chain-proc this aura; Aura::GetProcEffectMask refuses it both as the aura's own trigger and
--     as a triggered spell.
--   Chance 25 - the record's own ProcChance and the number the tooltip renders.
DELETE FROM `spell_proc` WHERE `SpellId` = 583248;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(583248, 0, 28, 0, 4096, 33554432, 65536, 1, 2, 0, 0, 0, 0, 25, 0, 0);
