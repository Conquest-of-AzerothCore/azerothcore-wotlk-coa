-- Stormwitch Staff never triggered Thunderstrike (#11308): its proc dummies carry DBC ProcFlags 0 and the world
-- had no spell_proc row, so Aura::GetProcEffectMask found no entry and the roll never happened (same cause as
-- Eliza's Pendant, #9883).
--
-- The tooltips promise a "$h%" chance on dealing direct magic damage to trigger a Thunderstrike. Grant the landed
-- done-spell mask of the magic damage class at the hit phase (PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG, ProcFlags
-- 65536) over every school and spell family; Chance stays 0 so SpellMgr::LoadSpellProcs defers to each record's
-- own ProcChance (5 for the base staff, 10 for the tiers) and Cooldown stays 0. Periodic ticks are not proc
-- events. Thunderstrike carries SPELL_ATTR3_SUPPRESS_CASTER_PROCS, so the strike does not retrigger itself.
--
-- Covers the base item's dummy (303052) and the higher tiers (312855, 316855, 320855), which trigger Thunderstrike
-- records 303001/312856/316856/320856. Thunderstrike's damage coefficients are not part of this change.
DELETE FROM `spell_proc` WHERE `SpellId` IN (303052, 312855, 316855, 320855);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(303052, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312855, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(316855, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(320855, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0);
