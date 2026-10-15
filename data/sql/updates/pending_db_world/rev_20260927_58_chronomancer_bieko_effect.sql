-- The Bieko Effect (706099): "While Hasten is active the cooldowns of Dimensional Divergence, Temporal Anomaly,
-- and Temporal Focus are reduced by $707312s1% every $712371t1 sec." The passive's only effect is aura 42
-- triggering 712371 (TARGET_UNIT_CASTER, SPELL_AURA_PERIODIC_TRIGGER_SPELL every 2000 ms for DurationIndex 29,
-- 12 sec - Hasten 801304's own duration), which triggers 707312. Spell.dbc gives 706099 ProcFlags 0 and no
-- `spell_proc` row existed, so SpellMgr::LoadSpellProcs skipped it and the talent never fired.
-- The row keys the proc on Hasten: SpellFamilyName 28 with SpellFamilyMask0 0x10000000 (268435456), the family
-- flag only Hasten 801304 and its unobtainable variant 803382 carry. Hasten is a positive DmgClass 1 spell, so
-- ProcFlags 17408 = PROC_FLAG_DONE_SPELL_NONE_DMG_CLASS_POS (0x400) | PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_POS
-- (0x4000); SpellTypeMask 4 = PROC_SPELL_TYPE_NO_DMG_HEAL, because Hasten neither damages nor heals;
-- SpellPhaseMask 2 = PROC_SPELL_PHASE_HIT. Chance is the record's own ProcChance (100). Hasten carries
-- SPELL_ATTR4_ALLOW_CAST_WHILE_CASTING, which Spell::Spell turns into TRIGGERED_IGNORE_CAST_IN_PROGRESS |
-- TRIGGERED_CAST_DIRECTLY even for the player's own cast, so Aura::GetProcEffectMask treats it as a triggered
-- spell; AttributesMask 2 = PROC_ATTR_TRIGGERED_CAN_PROC lets it proc.
-- 707312's three effects are the custom effect 192, which reduces the remaining cooldown of the spell named in
-- MiscValue by BasePoints percent (Profound Enlightenment 680953 states the same effect as "reducing the
-- remaining cooldown of Testaments by $s1%"). This core leaves effect 192 on EffectNULL, so
-- spell_ascension_the_bieko_effect applies it for 802790 Dimensional Divergence, 806315 Temporal Anomaly and
-- 806165 Temporal Focus.
DELETE FROM `spell_proc` WHERE `SpellId` = 706099;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706099, 0, 28, 268435456, 0, 0, 17408, 4, 2, 0, 2, 0, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 707312 AND `ScriptName` = 'spell_ascension_the_bieko_effect';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(707312, 'spell_ascension_the_bieko_effect');
