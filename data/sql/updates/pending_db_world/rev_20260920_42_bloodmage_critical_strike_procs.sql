-- Three Bloodmage passives whose tooltip fires on the caster's own critical strikes, with no ability named.
-- Each carries an aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL) effect on a correctly-built trigger spell, but
-- Spell.dbc gives every one of these records ProcFlags 0 and no `spell_proc` row existed, so
-- SpellMgr::LoadSpellProcs skipped them ("Skip if no proc flags in DBC") and Aura::GetProcEffectMask
-- returned a zero mask. Same reasoning and shape as rev_20260918_30_bloodmage_twisted_magic_proc, which
-- fixes the same defect for the same kind of "critical strikes" tooltip.
--
-- Shared columns. `SpellFamilyName`/`SpellFamilyMask` are 0 on all three rows: none of these tooltips names
-- an ability, so nothing restricts which spell may crit. `SpellPhaseMask` 2 (PROC_SPELL_PHASE_HIT) and
-- `HitMask` 2 (PROC_HIT_CRITICAL) are the literal reading of "critical strikes"; a crit is only known at
-- hit time. `SpellTypeMask` 1 (PROC_SPELL_TYPE_DAMAGE) keeps healing crits out. `Chance` is each record's
-- own ProcChance (100 - every qualifying crit, as the tooltips state no percentage). AttributesMask is 0
-- (PROC_ATTR_TRIGGERED_CAN_PROC not set): these fire on the player's own direct casts and swings, and no
-- helper spell was identified that would otherwise need to proc them.
--
-- `ProcFlags` 69972 is the repository's established "direct damage done" set - DONE_MELEE_AUTO_ATTACK 0x4 |
-- DONE_SPELL_MELEE_DMG_CLASS 0x10 | DONE_RANGED_AUTO_ATTACK 0x40 | DONE_SPELL_RANGED_DMG_CLASS 0x100 |
-- DONE_SPELL_NONE_DMG_CLASS_NEG 0x1000 | DONE_SPELL_MAGIC_DMG_CLASS_NEG 0x10000 - the same value used by
-- rev_20260918_30/32/33. DONE_PERIODIC 0x40000 is deliberately absent: that is what makes "direct" true.
--
-- 804599 Everhungry: "Direct critical strikes now increase your haste by $802029s1% for $802029d." Aura 42
-- on Everhungry 802029 (MOD_MELEE_RANGED_HASTE and HASTE_SPELLS, both BasePoints 9 -> +10%, duration
-- index 28, TargetA 1 = caster).
-- 706656 Crimson Curse: "Your direct damage critical strikes increase the damage the target takes from
-- bleed effects by $560288s1% for $560288d." Aura 42 on Lacerations 560288
-- (MOD_MECHANIC_DAMAGE_TAKEN_PERCENT, MiscValue 15 = MECHANIC_BLEED, BasePoints 29 -> +30%, TargetA 6).
-- 680684 Fleshbending: "Your critical strikes now increase the critical strike chance of all party and
-- raid members by $582766s1% for $582766d." Aura 42 on Fleshbending 582766
-- (SPELL_EFFECT_APPLY_AREA_AURA_RAID, MOD_CRIT_PCT, BasePoints 4 -> +5%, radius index 12, TargetA 1). The
-- aura-42 effect's own BasePoints 49 is dead data: AuraEffect::HandleProcTriggerSpellAuraProc ignores the
-- amount entirely and the +5% comes from 582766.
DELETE FROM `spell_proc` WHERE `SpellId` IN (804599, 706656, 680684);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(804599, 0, 0, 0, 0, 0, 69972, 1, 2, 2, 0, 0, 0, 100, 0, 0),
(706656, 0, 0, 0, 0, 0, 69972, 1, 2, 2, 0, 0, 0, 100, 0, 0),
(680684, 0, 0, 0, 0, 0, 69972, 1, 2, 2, 0, 0, 0, 100, 0, 0);
