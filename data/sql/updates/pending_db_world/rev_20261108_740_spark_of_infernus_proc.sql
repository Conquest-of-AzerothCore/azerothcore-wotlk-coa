-- Spark of Infernus never procced: its equip dummies carry DBC ProcFlags 0 and the world had no spell_proc row,
-- so Aura::GetProcEffectMask found no entry and the roll never happened (#11660).
--
-- The tooltips promise a chance on dealing direct damage with a spell to sear the target for Fire damage over
-- time. Grant the landed done-spell mask of the magic damage class at the hit phase
-- (PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG, ProcFlags 65536) over every school and spell family; Chance is left 0
-- so SpellMgr::LoadSpellProcs defers to the record's own ProcChance (8 on the base dummy, 12 on the tiers) and
-- Cooldown stays 0 because no tooltip names an internal cooldown. Periodic ticks are not direct damage and are
-- not proc events. Same shape as the Eliza's Pendant repair (rev_20261031_96_elizas_pendant_proc.sql).
--
-- Covers the base item's dummy (201007) and the worldforged tiers (312227, 316227, 320227), which trigger the
-- Fire damage over time 201008/312228/316228/320228.
DELETE FROM `spell_proc` WHERE `SpellId` IN (201007, 312227, 316227, 320227);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(201007, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312227, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(316227, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(320227, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0);
