--
-- Stormbringer on-cast talents: Spell.dbc gives these passives ProcFlags 0, so
-- SpellMgr::LoadSpellProcs never builds an entry for them and their PROC_TRIGGER_SPELL
-- auras can never fire. Titanstorm is the exception with ProcFlags 327680, whose
-- generated entry carries no family filter and fires on every target hit; the explicit
-- row below replaces it, because generation is skipped for spells already in the map.
-- ProcFlags 65536: done negative magic spell; SpellPhaseMask 1: cast, not each target hit.
-- Family masks over the 953 SpellFamilyName 22 spells:
--   mask0 0x2000000 Electrocute, mask0 0x800 Shock, mask0 0x4000 Gale,
--   mask1 0x10 Call Lightning and Aeroblast, which Tempest Calling 707615 swaps in.
-- Titanstorm (#686): Call Lightning or Electrocute, tooltip 801854.
-- Cyclone's Recharge (#1771): Shock, Gale or Electrocute, tooltip 300828.
-- Evergale (#2813): Call Lightning or Aeroblast, tooltip 705716.
-- Master Airbender (#2815): Gale, tooltips 680878 / 6801879 / 681010.
-- Focal Point (#3079): Call Lightning or Aeroblast, tooltip 680876.
DELETE FROM `spell_proc` WHERE `SpellId` IN (300827, 705717, 705719, 706629, 801869);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(300827, 0, 22, 33572864, 0, 0, 65536, 0, 1, 0, 0, 0, 0, 100, 0, 0),
(705717, 0, 22, 0, 16, 0, 65536, 0, 1, 0, 0, 0, 0, 100, 0, 0),
(705719, 0, 22, 16384, 0, 0, 65536, 0, 1, 0, 0, 0, 0, 100, 0, 0),
(706629, 0, 22, 0, 16, 0, 65536, 0, 1, 0, 0, 0, 0, 100, 0, 0),
(801869, 0, 22, 33554432, 16, 0, 65536, 0, 1, 0, 0, 0, 0, 100, 0, 0);
