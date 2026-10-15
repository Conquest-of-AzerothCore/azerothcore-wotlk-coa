-- Borrowed Time (680373): "Taking Physical damage now heals you equal to $s1% of the damage dealt. Can
-- only occur once per sec." Its effect 0 is EffectBasePoints 9 / DieSides 1 -> 10 (the $s1 percentage)
-- with EffectApplyAuraName 354 and EffectTriggerSpell 680374. Aura type 354 has no handler in this core
-- (SpellAuraEffects.cpp's dispatch table holds "//354 unknown Ascension aura" and a null entry is
-- replaced by AuraEffect::HandleNoImmediateEffect), so applying the aura is a no-op and nothing reads its
-- amount; 680374 is a single SPELL_EFFECT_HEAL with EffectBasePoints 0 / DieSides 0, so it heals zero
-- unless a caster supplies the base point. (680374's AuraDescription "Critical damage of Shatter Echo
-- increased by ${$w1}%" is stale DBC text that contradicts its own effects; 680373's tooltip is the
-- contract.) The new module script aura_ascension_borrowed_time rewrites effect 0 to SPELL_AURA_DUMMY in
-- ApplyTimeContracts, the same treatment the merged Timeline Tether 804505 row already relies on, and
-- forwards damage * amount / 100 into 680374 as SPELLVALUE_BASE_POINT0; 680374 carries
-- AttributesEx3 0x20000000 (SPELL_ATTR3_IGNORE_CASTER_MODIFIERS) and AttributesEx4 0x100
-- (SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS) with a zero bonus multiplier, so the forwarded value is
-- delivered as authored instead of being rescaled by spell power. Spell.dbc gives 680373's record
-- ProcFlags 0 and no `spell_proc` row existed, so no proc entry exists and Aura::GetProcEffectMask
-- returns 0 (SpellAuras.cpp:2150-2154). ProcFlags is 0x100000 = 1048576 (PROC_FLAG_TAKEN_DAMAGE,
-- SpellMgr.h:140), the flag Unit::CalculateMeleeDamage sets on the victim for any damaging hit
-- (Unit.cpp:1976) and Spell::DoAllEffectOnTarget for spell damage (Spell.cpp:2909). SchoolMask is 1
-- (SPELL_SCHOOL_MASK_NORMAL) for "Physical"; SpellMgr::CanSpellTriggerProcOnEvent checks the event's
-- school against it (SpellMgr.cpp:921-922), and ProcEventInfo::GetSchoolMask falls back to the damage
-- info's school for a melee swing that has no SpellInfo (Unit.cpp:320-332). SpellFamilyName and the three
-- family masks stay 0: PROC_FLAG_TAKEN_DAMAGE is not part of SPELL_PROC_FLAG_MASK, so the family check is
-- skipped and a plain white hit must still qualify. SpellTypeMask and SpellPhaseMask are 0 for the same
-- reason - neither is checked for this flag (SpellMgr.cpp:925-943). HitMask stays 0, which for a TAKEN
-- flag defaults to normal plus critical hits. Chance is the record's own ProcChance (100) and Cooldown is
-- 1000 ms, which is the tooltip's "Can only occur once per sec".
DELETE FROM `spell_script_names` WHERE `spell_id` = 680373 AND `ScriptName` = 'aura_ascension_borrowed_time';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(680373, 'aura_ascension_borrowed_time');

DELETE FROM `spell_proc` WHERE `SpellId` = 680373;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680373, 1, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 100, 1000, 0);
