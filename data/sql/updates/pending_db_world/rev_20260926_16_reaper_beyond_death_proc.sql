-- Beyond Death: 8% chance (DBC ProcChance 8, tooltip $h%) from the Reliquary's triggered Soul Bolts.
-- rev_20260920_17_reaper_talent_procs.sql sorts after rev_1790304941011984869.sql and reset this row to
-- Chance 100 without PROC_ATTR_TRIGGERED_CAN_PROC, so the triggered Soul Bolts could never proc it.
DELETE FROM `spell_proc` WHERE `SpellId` = 301193;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (301193, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 2, 0, 0, 8, 0, 0);
