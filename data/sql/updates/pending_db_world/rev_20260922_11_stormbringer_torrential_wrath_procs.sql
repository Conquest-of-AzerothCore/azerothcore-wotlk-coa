-- Two Stormbringer (class 16, SpellFamilyName 22) passives whose whole mechanic is an aura 42
-- (SPELL_AURA_PROC_TRIGGER_SPELL) effect on a correctly built trigger spell. Spell.dbc gives both records
-- ProcFlags 0 and no `spell_proc` row existed, so SpellMgr::LoadSpellProcs skipped them ("Skip if no proc
-- flags in DBC") and Aura::GetProcEffectMask returned a zero mask ("only auras with spell proc entry can
-- trigger proc"): neither trigger could ever fire. Same defect and shape as
-- rev_20260920_40_bloodmage_cast_proc_triggers and rev_20260920_42_bloodmage_critical_strike_procs.
--
-- Both aura-42 effects carry EffectSpellClassMask 0/0/0, so the ability restriction each tooltip states
-- exists nowhere in Spell.dbc and has to come from this table. Every Torrential Wrath rank (804017,
-- 503352-503359) carries SpellFamilyFlags (0, 0x1, 0x20) and every Stormbringer Deluge rank (806400,
-- 807713-807717) carries (0, 0x8000, 0); all of them are DmgClass MAGIC and harmful, so the restriction is
-- SpellFamilyName 22 plus SpellFamilyMask1, and the only DONE proc flag the core raises for them is
-- DONE_SPELL_MAGIC_DMG_CLASS_NEG 0x10000 = 65536. SchoolMask stays 0: neither tooltip names a school.
-- AttributesMask is 0 (PROC_ATTR_TRIGGERED_CAN_PROC not set): both proc sources are abilities the player
-- casts directly. `Chance` is each record's own ProcChance (100).
--
-- 572310 Shockingly Powerful: "Critical strikes with Torrential Wrath now trigger Conductive." Effect 0 is
-- aura 42 on Conduction 567560 (SPELL_EFFECT_SCHOOL_DAMAGE, TargetA 6 = target enemy), the spell the DBC
-- record actually names; the trigger needs a victim, so it runs at hit time. SpellFamilyMask1 1 is
-- Torrential Wrath alone, SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT) with HitMask 2 (PROC_HIT_CRITICAL) is the
-- literal reading of "critical strikes", and SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE) keeps anything but a
-- damaging hit out. Effect 1 (SPELL_AURA_ADD_PCT_MODIFIER, MiscValue 22 = SPELLMOD_DOT, +50% on
-- SpellFamilyMask1 0x10000 = Stormflow) is a native spell modifier and is untouched by this row:
-- AuraEffect::HandleProc has no case for modifier auras, and `Charges` 0 means nothing is consumed.
--
-- 806409 Kinetic Energy: "Casting Torrential Wrath or Deluge now grants you a stack of Kinetic Energy."
-- Effect 0 is aura 42 on Kinetic Energy 806410 (SPELL_AURA_MOD_CRIT_PCT, BasePoints 1 + DieSides 1 = +2%,
-- StackAmount 3, DurationIndex 29 = 12000 ms, TargetA 1 = caster), which needs no unit target, so
-- SpellPhaseMask 1 (PROC_SPELL_PHASE_CAST) delivers the tooltip's "Casting" even when Deluge, a ground area
-- spell, lands on nothing. SpellFamilyMask1 32769 = 0x8001 is Torrential Wrath (bit 0) plus Deluge (bit 15).
-- HitMask and SpellTypeMask stay 0: at cast phase the core raises no hit result and no damage or heal has
-- happened yet, so SpellMgr::CanSpellTriggerProcOnEvent skips both checks only while they are unset.
DELETE FROM `spell_proc` WHERE `SpellId` IN (572310, 806409);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(572310, 0, 22, 0, 1, 0, 65536, 1, 2, 2, 0, 0, 0, 100, 0, 0),
(806409, 0, 22, 0, 32769, 0, 65536, 0, 1, 0, 0, 0, 0, 100, 0, 0);
