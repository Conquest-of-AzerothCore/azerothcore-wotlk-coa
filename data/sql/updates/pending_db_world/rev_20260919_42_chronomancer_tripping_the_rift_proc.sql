-- Tripping the Rift (520173): "Casting Clasp of Infinity now reduces the cooldown of Backtrack by
-- $/1000;521214s1 sec." Its effect 0 is aura 42 (proc trigger spell) on 521214, a single
-- SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN (165) with EffectMiscValue 706973 (Backtrack),
-- EffectBasePoints -10001 (die 1 => -10000 ms) and implicit target 1 (caster). Effect 165 is
-- implemented, so the child is sound - but Spell.dbc gives 520173's record ProcFlags 0 and no
-- `spell_proc` row existed, so SpellMgr's generation pass skipped it (it only generates for records
-- with a nonzero ProcFlags) and Aura::GetProcEffectMask returned 0 for want of a proc entry. The
-- cooldown reduction never happened.
-- Proc on the cast of Clasp of Infinity 805847 (family 28, word0 0x800000 = 8388608 - its own
-- SpellFamilyFlags), the ability the tooltip names. Clasp is SPELL_DAMAGE_CLASS_MAGIC and negative (it
-- roots), so the attacker flag is PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG (65536); its effects are
-- auras only (26 root, 271, 23 periodic trigger) with no SPELL_EFFECT_SCHOOL_DAMAGE or heal, so
-- Unit::ProcSkillsAndAuras has neither a DamageInfo nor a HealInfo for the HIT-phase event and computes
-- SpellTypeMask as PROC_SPELL_TYPE_NO_DMG_HEAL (4). SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT). Chance is
-- the record's own ProcChance (100 - always, as the tooltip states no percentage). This is a
-- field-for-field copy of the Paradox precedent's shape with Clasp of Infinity's own family mask.
DELETE FROM `spell_proc` WHERE `SpellId` = 520173;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(520173, 0, 28, 8388608, 0, 0, 65536, 4, 2, 0, 0, 0, 0, 100, 0, 0);
