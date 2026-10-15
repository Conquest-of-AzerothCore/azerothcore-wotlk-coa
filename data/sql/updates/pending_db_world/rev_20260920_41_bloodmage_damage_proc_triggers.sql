-- Three Bloodmage passives whose tooltip fires when a named ability lands on a target. Each carries an
-- aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL) effect on a correctly-built trigger spell, but Spell.dbc gives
-- every one of these records ProcFlags 0 and no `spell_proc` row existed, so SpellMgr::LoadSpellProcs
-- skipped them ("Skip if no proc flags in DBC") and Aura::GetProcEffectMask returned a zero mask.
-- Same reasoning and shape as rev_20260918_32_bloodmage_council_assembled_proc.
--
-- All three use `SpellPhaseMask` 2 (PROC_SPELL_PHASE_HIT), because every one of these trigger spells needs
-- the ability's own victim: at CAST phase Spell::cast passes no victim, and a trigger whose TargetA is 6
-- (TARGET_UNIT_TARGET_ENEMY) would be cast with a null target. `Chance` is each record's ProcChance (100).
--
-- 680733 Bloodcraft: "Your damage dealt by Darkfallen Lament now applies Bloodcraft to affected enemies,
-- reducing damage dealt by $524182s1% for $524182d, stacking $524182u times." Aura 42 on Bloodcraft
-- 524182 (MOD_DAMAGE_PERCENT_DONE, MiscValue 127 = all schools, BasePoints -3 -> -2%, StackAmount 4,
-- TargetA 6). Darkfallen Lament 524181, 630874 and 680828 all carry SpellFamilyFlags (0, 0, 4096), hence
-- SpellFamilyMask2 4096.
--
-- 802315 Blood Parasites: the tooltip's second clause, "increases spell critical strike chance against the
-- target by $800988s1% for $800988d". Effect 1 is aura 42 on Blood Parasites 800988
-- (MOD_ATTACKER_SPELL_AND_WEAPON_CRIT_CHANCE, BasePoints 2 -> +3%, TargetA 6). Effect 0 (aura 107
-- SPELLMOD_EFFECT1 +30 on ClassMask (0, 128, 0)) is the Rage clause and already works through the generic
-- spellmod path; it is untouched here. Taldaram's Torment 800772 and its ranks 802568-802573/802580 carry
-- SpellFamilyFlags (0, 0, 2097152) with DmgClass MAGIC and are harmful, hence SpellFamilyMask2 2097152
-- and ProcFlags 65536 = DONE_SPELL_MAGIC_DMG_CLASS_NEG.
--
-- 704692 Corrupted Blood: "When you use Taldaram's Torment on a Humanoid or Beast it now corrupts their
-- blood, increasing your damage dealt against them by $532623s1%." Aura 42 on Corrupted Blood 532623
-- (MOD_DAMAGE_FROM_CASTER, BasePoints 9 -> +10%, EffectSpellClassMask (6291456, 0, 0) = Veinburst 2097152
-- plus Reave 4194304, TargetA 6). Same proc source and flags as 802315. The tooltip's "on a Humanoid or
-- Beast" gate has no `spell_proc` column, so it is expressed with two CONDITION_SOURCE_TYPE_SPELL_PROC
-- rows below: Aura::GetProcEffectMask evaluates
-- sConditionMgr->GetConditionsForNotGroupedEntry(CONDITION_SOURCE_TYPE_SPELL_PROC, GetId()) against
-- ConditionSourceInfo(actor, actionTarget), and ConditionTarget 1 selects the action target. Distinct
-- ElseGroup values make the two creature types an OR.
--
-- `SpellTypeMask` is 1 (PROC_SPELL_TYPE_DAMAGE) where the tooltip says "damage dealt by" (680733)
-- and 0 elsewhere: Taldaram's Torment and Corrupted Blood are applied/used, and a spell that only
-- applies an aura reaches the proc system with PROC_SPELL_TYPE_NO_DMG_HEAL. `HitMask` stays 0, which for a
-- DONE proc already defaults to NORMAL | CRITICAL | ABSORB (SpellMgr::CanSpellTriggerProcOnEvent); BLOCK
-- and FULL_BLOCK are deliberately left out because a fully blocked hit deals no damage. AttributesMask is
-- 0 on all three rows: no helper spell was found that casts Darkfallen Lament or Taldaram's Torment as a
-- triggered effect of something else. SchoolMask is 0 (no tooltip states a school).
DELETE FROM `spell_proc` WHERE `SpellId` IN (680733, 802315, 704692);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680733, 0, 26, 0, 0, 4096, 69972, 1, 2, 0, 0, 0, 0, 100, 0, 0),
(802315, 0, 26, 0, 0, 2097152, 65536, 0, 2, 0, 0, 0, 0, 100, 0, 0),
(704692, 0, 26, 0, 0, 2097152, 65536, 0, 2, 0, 0, 0, 0, 100, 0, 0);

-- Corrupted Blood's "on a Humanoid or Beast" gate. CONDITION_SOURCE_TYPE_SPELL_PROC = 24,
-- CONDITION_CREATURE_TYPE = 24, CREATURE_TYPE_BEAST = 1, CREATURE_TYPE_HUMANOID = 7
-- (src/server/game/Conditions/ConditionMgr.h, src/server/shared/SharedDefines.h).
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 24 AND `SourceEntry` = 704692;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(24, 0, 704692, 0, 0, 24, 1, 7, 0, 0, 0, 0, 0, '', 'Corrupted Blood only corrupts a Humanoid target'),
(24, 0, 704692, 0, 1, 24, 1, 1, 0, 0, 0, 0, 0, '', 'Corrupted Blood only corrupts a Beast target');
