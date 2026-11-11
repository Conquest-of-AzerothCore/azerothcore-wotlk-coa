-- Giant Ruby Eye never stacked Ruby Flame: its equip aura carries DBC ProcFlags 0 and the world had no spell_proc
-- row, so Aura::GetProcEffectMask found no entry and the roll never happened (#11733).
--
-- The tooltip reads "Your non-critical direct damaging spell hits increase your spell critical strike rating".
-- "Spell hits" that deal direct damage are the landed done-spell events of the magic damage class at the hit phase
-- (PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG, ProcFlags 65536), the same mask as the Spark of Infernus repair
-- (rev_20261108_740_spark_of_infernus_proc.sql); the rating is spell crit rating (MiscValue 1024), so melee and
-- ranged events are not widened in. HitMask 1 (PROC_HIT_NORMAL) is the tooltip's "non-critical". Chance is left 0
-- so SpellMgr::LoadSpellProcs defers to the record's ProcChance of 100, and Cooldown stays 0 because no tooltip
-- names one. Periodic ticks are not direct damage and are not proc events. Clearing the stacks on a critical
-- strike is not part of this repair.
--
-- Covers the base item's aura (201009) and the worldforged tiers (312231, 316231, 320231), which trigger
-- Ruby Flame 201010/312232/316232/320232.
DELETE FROM `spell_proc` WHERE `SpellId` IN (201009, 312231, 316231, 320231);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(201009, 0, 0, 0, 0, 0, 65536, 1, 2, 1, 0, 0, 0, 0, 0, 0),
(312231, 0, 0, 0, 0, 0, 65536, 1, 2, 1, 0, 0, 0, 0, 0, 0),
(316231, 0, 0, 0, 0, 0, 65536, 1, 2, 1, 0, 0, 0, 0, 0, 0),
(320231, 0, 0, 0, 0, 0, 65536, 1, 2, 1, 0, 0, 0, 0, 0, 0);
