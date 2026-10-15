-- Temporal Convergence (807588): "Your Wand of Time now has a $h% chance to reset its own cooldown."
-- Its effect 0 is aura 42 (proc trigger spell) triggering 807756, whose single effect is 195
-- (SPELL_EFFECT_ASCENSION_RESET_COOLDOWN, handler Spell::EffectAscensionResetCooldown at
-- SpellEffects.cpp) with EffectMiscValue 520175 (Wand of Time) and EffectMiscValueB 0, i.e. clear that
-- spell's own cooldown without touching its shared category. The payload is implemented; Spell.dbc gives
-- 807588's record ProcFlags 0 and no `spell_proc` row existed, so LoadSpellProcs skips it
-- (SpellMgr.cpp:2249 "Skip if no proc flags in DBC") and Aura::GetProcEffectMask returns 0 for a missing
-- proc entry (SpellAuras.cpp:2150-2154), so 807756 could never fire. Proc on the ranged class damage of
-- Wand of Time (family 28, word1 0x100000 = 1048576: 520175's own SpellFamilyFlags are
-- [16781312, 1048576, 0] and every rank 520702-520707 plus 524960 and 520165 carry the same word1 bit,
-- so one mask covers the whole chain), the only ability the tooltip names. Wand of Time is Spell.dbc
-- DmgClass 3 (RANGED) without SPELL_ATTR2_AUTO_REPEAT, so Spell::prepareDataForTriggerSystem gives its
-- events PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS = 0x100 = 256 (Spell.cpp:2278-2288, SpellMgr.h:122). Its
-- effect 1 is SPELL_EFFECT_SCHOOL_DAMAGE, so the HIT event carries real damage and
-- Unit::ProcSkillsAndAuras computes SpellTypeMask PROC_SPELL_TYPE_DAMAGE (1) (Unit.cpp:7121-7133).
-- SpellPhaseMask is 2 (PROC_SPELL_PHASE_HIT); Spell::_cast calls SendSpellCooldown() (Spell.cpp:3983)
-- before handle_immediate(), so the cooldown already exists when the hit-phase proc clears it. HitMask
-- stays 0 for the default normal/critical/absorb set. Chance is the record's own ProcChance (40).
DELETE FROM `spell_proc` WHERE `SpellId` = 807588;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(807588, 0, 28, 0, 1048576, 0, 256, 1, 2, 0, 0, 0, 0, 40, 0, 0);
