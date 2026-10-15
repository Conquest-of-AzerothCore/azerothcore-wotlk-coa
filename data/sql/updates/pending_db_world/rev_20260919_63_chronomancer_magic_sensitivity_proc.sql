-- Magic Sensitivity (520171): "Critical strikes with Shatter Echo now increases the enemy's damage taken
-- from you by $520177s1% for $520177d." Its effect 0 is aura 42 (proc trigger spell) triggering 520177
-- (a target debuff applying SPELL_AURA_MOD_DAMAGE_FROM_CASTER, EffectBasePoints 9 / DieSides 1 -> +10%,
-- EffectMiscValue 127 = every school, DurationIndex 31 = 8000 ms, EffectSpellClassMask [0, 0, 0] - an
-- empty family mask is not inert here, SpellInfo::IsAffected returns true when familyFlags is empty
-- (SpellInfo.cpp:1422-1434), so the debuff raises damage from every family 28 spell of that caster, which
-- is what "damage taken from you" states). Spell.dbc gives 520171's record ProcFlags 0 and no `spell_proc`
-- row existed, so 520177 could never be applied. Proc on the ranged class damage of Shatter Echo
-- (family 28, word2 0x10 = 16: 804503's own SpellFamilyFlags are [0, 0, 20] and its ranks 572417 and
-- 807950-807953 carry the same bit), the only ability the tooltip names. Shatter Echo is Spell.dbc
-- DmgClass 3 (RANGED) without SPELL_ATTR2_AUTO_REPEAT, so its events carry
-- PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS = 0x100 = 256 (Spell.cpp:2278-2288, SpellMgr.h:122); its effects
-- 121/31 deal weapon-based damage, so the HIT event reports damage and Unit::ProcSkillsAndAuras computes
-- SpellTypeMask PROC_SPELL_TYPE_DAMAGE (1) (Unit.cpp:7121-7133). SpellPhaseMask is 2
-- (PROC_SPELL_PHASE_HIT) because a critical strike is only known once the spell lands, and HitMask is 2
-- (PROC_HIT_CRITICAL, SpellMgr.h:258) for the tooltip's "Critical strikes with". Chance is the record's
-- own ProcChance (100): the tooltip states no percentage, the crit requirement is the gate.
DELETE FROM `spell_proc` WHERE `SpellId` = 520171;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(520171, 0, 28, 0, 0, 16, 256, 1, 2, 2, 0, 0, 0, 100, 0, 0);
