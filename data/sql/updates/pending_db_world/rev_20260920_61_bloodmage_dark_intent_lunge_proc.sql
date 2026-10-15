-- Dark Intent (707622), the rank a Bloodmage actually owns (CharacterAdvancement class 20, and present in
-- the live-client capture): "When you Lunge at an enemy you now heal for $504831s1% of your maximum
-- health." Its single effect is SPELL_EFFECT_APPLY_AURA with aura 42 SPELL_AURA_PROC_TRIGGER_SPELL and
-- EffectTriggerSpell 504831 ("Heal 5%": SPELL_EFFECT_HEAL_PCT, BasePoints 4 + DieSides 1 = 5, on the
-- caster), ProcChance 100, and Spell.dbc ProcFlags 0x0. SpellMgr::LoadSpellProcs skips DBC fallback
-- generation for a record without proc flags ("Skip if no proc flags in DBC", SpellMgr.cpp) and no
-- `spell_proc` row existed, so Aura::GetProcEffectMask returned 0 and the heal never fired.
--
-- Lunge 500126 is the only family-26 record carrying SpellFamilyFlags (16777216, 0, 0), so
-- SpellFamilyName 26 with SpellFamilyMask0 16777216 scopes the row to it exactly. Lunge has DmgClass NONE
-- and is harmful, so ProcFlags 4096 = PROC_FLAG_DONE_SPELL_NONE_DMG_CLASS_NEG - the same pair of columns
-- the merged Cruel Intent row uses for the same ability
-- (704653 in rev_20260920_41_bloodmage_damage_proc_triggers.sql).
-- SpellTypeMask 0: "when you Lunge" is the use of the ability, not a damage or healing category.
-- SpellPhaseMask 2 = HIT, so the heal follows a landed Lunge ("at an enemy").
-- HitMask 0 leaves the DONE default (NORMAL | CRITICAL | ABSORB). AttributesMask 0: no helper spell casts
-- Lunge as a triggered effect of something else. DisableEffectsMask 0 (single effect), Charges 0
-- (ProcCharges 0, the passive is permanent), SchoolMask 0 (the tooltip states no school).
-- Chance stays 0 so SpellMgr::LoadSpellProcs takes the record's own ProcChance of 100, per
-- rev_20260919_20_coa_proc_chance_parity.sql.
--
-- The other id filed under the same issue, 705741 ("Reduces the cooldown of Aneurysm by 5 sec and
-- increases its duration by 1 sec"), needs no row: it is aura 107 with SPELLMOD_COOLDOWN and
-- SPELLMOD_DURATION, both consumed natively. It is also not obtainable by any route for class 20, and its
-- EffectSpellClassMask (0, 0, 268435456) selects Hemophobia 300786 rather than Aneurysm, so nothing here
-- touches it.
DELETE FROM `spell_proc` WHERE `SpellId` = 707622;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(707622, 0, 26, 16777216, 0, 0, 4096, 0, 2, 0, 0, 0, 0, 0, 0, 0);
