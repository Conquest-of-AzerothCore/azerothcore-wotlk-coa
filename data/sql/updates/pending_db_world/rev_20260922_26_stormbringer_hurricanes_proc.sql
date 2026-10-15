-- Hurricanes (300839): "Casting Unshackle now unshackles you, increasing your damage dealt by
-- $570129s1% for $570129d." -> +15% for 15 sec (570129 EffectBasePoints[0] 14 + EffectDieSides[0] 1,
-- DurationIndex 8 = 15000 ms). Its effect 0 is aura 42 (proc trigger spell) triggering 570129, whose
-- effect 0 is aura 79 (SPELL_AURA_MOD_DAMAGE_PERCENT_DONE) on the caster. The payload is a stock aura
-- handler; Spell.dbc gives 300839's record ProcFlags 0 and no `spell_proc` row existed, so LoadSpellProcs
-- skips it (SpellMgr.cpp "Skip if no proc flags in DBC") and Aura::GetProcEffectMask returns 0 for a
-- missing proc entry (SpellAuras.cpp:2148-2154), so 570129 could never be applied. Proc on casting
-- Unshackle (706625, SpellFamilyName 22, SpellFamilyFlags[0] = 16): a full Spell.dbc scan for family 22
-- with that bit returns exactly one record, so the mask addresses Unshackle and nothing else. Unshackle is
-- DmgClass 0 (SPELL_DAMAGE_CLASS_NONE) and positive, so Spell::DoAllEffectOnTarget gives its events
-- PROC_FLAG_DONE_SPELL_NONE_DMG_CLASS_POS = 0x00000400 = 1024 (bit 10 of enum ProcFlags, SpellMgr.h;
-- Spell.cpp:2763-2776). A prior version of this row used 65536 (0x10000), which is actually
-- PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG (bit 16) -- a different flag that Unshackle's cast never raises,
-- so CanSpellTriggerProcOnEvent's very first check ("eventInfo.GetTypeMask() & procEntry.ProcFlags") was
-- always 0 and the proc never fired; the resulting CastSpell of 570129 was never even attempted (no
-- SMSG_CAST_FAILED, no log line), matching the discriminating assertion's observed actual value of 0.
-- It deals no damage and no healing, so Unit::ProcSkillsAndAuras computes SpellTypeMask
-- PROC_SPELL_TYPE_NO_DMG_HEAL (4). SpellPhaseMask is 2 (PROC_SPELL_PHASE_HIT); the resulting action target
-- (the pet, since Unshackle's effects all target TARGET_UNIT_PET) is a valid non-null unit, so this is not
-- the CAST-phase-null-target bug worked around for Conjuration Mastery -- 570129's own effects target
-- TARGET_UNIT_CASTER, which SelectImplicitCasterObjectTargets resolves to the triggering caster regardless
-- of the explicit unit target passed to CastSpell. HitMask stays 0 for the default normal/critical/absorb
-- set, which covers the no-damage hit (DamageInfo sets PROC_HIT_NORMAL). Chance is the record's own
-- ProcChance (100). The DBC ProcFlags are deliberately not patched in C++ instead: 300839's
-- EffectSpellClassMask is all zeros, so the generated default entry would carry SpellFamilyName 0 and the
-- passive would proc on every positive non-damage cast.
DELETE FROM `spell_proc` WHERE `SpellId` = 300839;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(300839, 0, 22, 16, 0, 0, 1024, 4, 2, 0, 0, 0, 0, 100, 0, 0);
