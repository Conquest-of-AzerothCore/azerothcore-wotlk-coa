-- Grim Omen (800154): "Critical strikes with Ravenous Strike or Bloodfang Bite, or using Howl spells, now
-- triggers Call of the Darkwing." Effect 0 is aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL) on Call of the
-- Darkwing 801958, a stock SPELL_EFFECT_SUMMON (MiscValue 50069, DieSides 2, TargetA 22 = a destination
-- around the caster, so it needs no unit target). But Spell.dbc gives 800154 ProcFlags 0 and no
-- `spell_proc` row existed, so SpellMgr::LoadSpellProcs skipped the record ("Skip if no proc flags in
-- DBC") and Aura::GetProcEffectMask returned a zero mask: the aura could never fire. Same reasoning and
-- shape as rev_20260918_32_bloodmage_council_assembled_proc. (The aura-42 effect's BasePoints 9 /
-- DieSides 4 / EffectRealPointsPerLevel 0.35 are dead data here: AuraEffect::HandleProcTriggerSpellAuraProc
-- ignores the amount and the chance comes from the proc entry.)
--
-- This tooltip carries two different proc conditions - "critical strikes with Ravenous Strike or Bloodfang
-- Bite" and "using Howl spells", the second with no critical requirement - and a single `spell_proc` entry
-- has one HitMask/SpellPhaseMask pair. This row therefore admits the widest set the tooltip allows and the
-- CheckProc handler aura_ascension_bloodmage_grim_omen
-- (modules/mod-ascension-compat/src/AscensionBloodmageProcs.cpp) applies the per-family rule: Howls only
-- at PROC_SPELL_PHASE_CAST, Ravenous Strike and Bloodfang Bite only at PROC_SPELL_PHASE_HIT with
-- PROC_HIT_CRITICAL. Without the script this row would also fire on non-critical Ravenous Strikes and
-- Bloodfang Bites, so the two changes belong together.
--
-- Family masks, all read from Spell.dbc family 26: Ravenous Strike 500123/501671-501679 (0, 1, 0);
-- Bloodfang Bite 501695-501697/503613-503615/572549-572551/800156 (0, 8388608, 0); Shadow Howl 806177 and
-- Wicked Howl 804207 (0, 0, 128); Night Hunter's Howl 500124/501680-501686 (0, 0, 2048); Blood Howl 800782
-- (0, 0, 131072); Monstrous Howl 804811 (0, 4, 131072). Union: SpellFamilyMask1 8388613 (1 + 4 + 8388608)
-- and SpellFamilyMask2 133248 (128 + 2048 + 131072).
--
-- `ProcFlags` 81936 = DONE_SPELL_MELEE_DMG_CLASS 0x10 | DONE_SPELL_MAGIC_DMG_CLASS_POS 0x4000 |
-- DONE_SPELL_MAGIC_DMG_CLASS_NEG 0x10000: Ravenous Strike, Bloodfang Bite, Night Hunter's Howl and
-- Monstrous Howl are DmgClass MELEE, while Shadow, Wicked and Blood Howl are DmgClass MAGIC with both
-- polarities possible. `SpellPhaseMask` 3 (CAST | HIT) admits both clauses; the script picks the right one
-- per family. `HitMask` is 0 on purpose: setting PROC_HIT_CRITICAL here would also forbid the Howl clause,
-- and at CAST phase with DONE flags a set HitMask would start being enforced
-- (SpellMgr::CanSpellTriggerProcOnEvent). `Chance` is the record's own ProcChance (100).
-- SchoolMask/SpellTypeMask are 0 and AttributesMask is 0 (PROC_ATTR_TRIGGERED_CAN_PROC not set): all five
-- proc sources are abilities the player casts directly.
DELETE FROM `spell_proc` WHERE `SpellId` = 800154;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(800154, 0, 26, 0, 8388613, 133248, 81936, 0, 3, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 800154 AND `ScriptName` = 'aura_ascension_bloodmage_grim_omen';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(800154, 'aura_ascension_bloodmage_grim_omen');
