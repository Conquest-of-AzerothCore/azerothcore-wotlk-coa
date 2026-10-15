-- Magic Erosion (706046): "Your Decomposition now deals $s1% more damage and applies Magic Erosion to
-- the target, increasing attackers chance to hit the target with spells by $570060s1% for $570060d."
-- Effect 0 (aura 108 ADD_PCT_MODIFIER, MiscValue 22 = SPELLMOD_DOT, +10%, class-masked to Decomposition's
-- SpellFamilyFlags word1 524288) is native and already works. Effect 1 is aura 42 (proc trigger spell) on
-- 570060, a 30 s target debuff whose single effect is aura 186
-- (SPELL_AURA_MOD_ATTACKER_SPELL_HIT_CHANCE, BasePoints 2 = +3%, implicit target 6 = the enemy), native
-- in Unit::MagicSpellHitResult. Only the proc gate was missing: Spell.dbc gives 706046 ProcFlags 0,
-- SpellMgr::LoadSpellProcs generates no entry for such a record, and Aura::GetProcEffectMask returns 0
-- without one, so the debuff was never applied.
-- Columns, all read from Spell.dbc this session:
--   SpellFamilyName 28 / SpellFamilyMask1 524288 - Decomposition 800856's own SpellFamilyName and
--     SpellFamilyFlags word1. The aura-42 effect itself carries an empty EffectSpellClassMask, so the
--     row is what restricts the debuff to the ability the tooltip names.
--   ProcFlags 65536 (PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG) - 800856 has DmgClass 1 (MAGIC) and is
--     harmful, the case Spell.cpp fills in for a negative magic-class hit.
--   SpellTypeMask 4 (PROC_SPELL_TYPE_NO_DMG_HEAL) - 800856 has no SPELL_EFFECT_SCHOOL_DAMAGE effect (only
--     APPLY_AURA periodic damage and APPLY_AURA 271), so Unit::ProcSkillsAndAuras sees no damage or heal
--     amount for the cast's own HIT-phase event and computes NO_DMG_HEAL, the Melt Reality case verified
--     empirically for rev_20260919_30_chronomancer_gift_of_the_timeways_proc.sql.
--   SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT) - the debuff lands on the target Decomposition hit.
--   HitMask 0 - default NORMAL|CRITICAL|ABSORB for a DONE proc.
--   Chance 100 - the record's own ProcChance; the tooltip states no percentage.
DELETE FROM `spell_proc` WHERE `SpellId` = 706046;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706046, 0, 28, 0, 524288, 0, 65536, 4, 2, 0, 0, 0, 0, 100, 0, 0);
