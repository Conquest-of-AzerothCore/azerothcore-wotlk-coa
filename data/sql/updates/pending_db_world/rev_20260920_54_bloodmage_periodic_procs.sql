-- Four Bloodmage passives that the tooltips gate on periodic damage or healing: Saturating Sutures
-- (504098), Infected Blood (805035), Lingering Essence (680695) and Sovereignty (806049). Each has a single
-- SPELL_AURA_PROC_TRIGGER_SPELL (aura 42) effect, Spell.dbc ProcFlags 0 and no `spell_proc` row. Because
-- SpellMgr::LoadSpellProcs skips fallback generation for records without DBC proc flags
-- ("Skip if no proc flags in DBC"), SpellMgr::GetSpellProcEntry returned nullptr and
-- Aura::GetProcEffectMask returned 0: the auras were inert. Every row uses
-- ProcFlags 262144 = PROC_FLAG_DONE_PERIODIC and SpellPhaseMask 2 (HIT), the same shape as the merged
-- Blood Rush row in rev_20260917_80_bloodmage_blood_rush_proc.sql, and leaves Chance 0 so the record's own
-- ProcChance is used (rev_20260919_20_coa_proc_chance_parity.sql).
--
-- Saturating Sutures (504098): "Your periodic damage and healing has a $h% chance to reduce the cost of
-- your next Sanguine Mend by $504137s1%." Trigger 504137 is native: aura 108 SPELL_AURA_ADD_PCT_MODIFIER,
-- MiscValue 14 (SPELLMOD_COST), BasePoints -101, EffectSpellClassMask (524288, 0, 0), which is exactly the
-- nine Sanguine Mend ranks (504079-504086, 802310) as read from Spell.dbc. SpellTypeMask 3 =
-- PROC_SPELL_TYPE_DAMAGE | PROC_SPELL_TYPE_HEAL for "damage and healing". Record ProcChance 15.
--
-- Infected Blood (805035): "Periodic damage dealt now reduces the enemy's movement speed by $800983s1%."
-- Trigger 800983 "Infection" is native: aura 33 SPELL_AURA_MOD_DECREASE_SPEED, BasePoints -31, TargetA 6
-- (enemy), effect mechanic 11 (snare). SpellTypeMask 1 (damage only - the tooltip says "periodic damage").
-- The proc path casts the trigger at eventInfo.GetActionTarget(), i.e. the enemy taking the tick, which is
-- what "the enemy's movement speed" means. Record ProcChance 100. (805035 itself is SpellFamilyName 27,
-- not 26; irrelevant to a row keyed by SpellId, and this row sets no family restriction.)
--
-- Lingering Essence (680695): "Periodic damage and healing done now has a $h% chance to reduce the cooldown
-- of Vampyr's Kiss by $/1000;680824s1 sec." Trigger 680824 is a single SPELL_EFFECT_ASCENSION_MODIFY_
-- COOLDOWN (165), BasePoints -1001, MiscValue 504275 = Vampyr's Kiss rank 1 (the same constant
-- AscensionBloodmageSecondary.cpp names SPELL_VAMPYRS_KISS). SpellTypeMask 3 for "damage and healing".
-- Record ProcChance 50.
--
-- Sovereignty (806049): "Damage dealt by Crimson Tide now grants you Sovereignty." Trigger 504272 is
-- native: aura 108 MiscValue 14 (SPELLMOD_COST) BasePoints -11 and aura 107 MiscValue 17
-- (SPELLMOD_JUMP_TARGETS) DieSides 1, both with EffectSpellClassMask (0, 131072, 0) = the eight Bloodbolt
-- ranks, StackAmount 5. Crimson Tide's only effect (all nine ranks, 504129-504136 and 504282) is aura 3
-- SPELL_AURA_PERIODIC_DAMAGE, so it has no direct-damage event at all and PROC_FLAG_DONE_PERIODIC is the
-- only flag that can ever fire; a done-hit mask would never match. The row is scoped to Crimson Tide by
-- SpellFamilyName 26 and SpellFamilyMask0 16384, the SpellFamilyFlags (16384, 0, 0) that Spell.dbc gives
-- every Crimson Tide rank and no other family-26 record. SpellTypeMask 1. Record ProcChance 100.
--
-- AttributesMask stays 0 in all four rows: a periodic tick raises its proc event from
-- AuraEffect::PeriodicTick, not from a triggered spell cast, so PROC_ATTR_TRIGGERED_CAN_PROC is not needed.
DELETE FROM `spell_proc` WHERE `SpellId` IN (504098, 805035, 680695, 806049);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504098, 0, 0, 0, 0, 0, 262144, 3, 2, 0, 0, 0, 0, 0, 0, 0),
(805035, 0, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(680695, 0, 0, 0, 0, 0, 262144, 3, 2, 0, 0, 0, 0, 0, 0, 0),
(806049, 0, 26, 16384, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0);
