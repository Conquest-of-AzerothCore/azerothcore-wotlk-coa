-- #3716 Command Aura (524600): "... causing allied players to deal ... additional damage as Stormstrike
-- Damage when they deal direct damage." Command Aura's presence effect grants allies 537248
-- (SPELL_AURA_PROC_TRIGGER_SPELL_WITH_VALUE on 537249, Stormstrike Damage), but Spell.dbc ships ProcFlags 0
-- for 537248 and no spell_proc row exists anywhere in the tree, so SpellMgr::LoadSpellProcs never builds an
-- entry ("Skip if no proc flags in DBC") and the aura can never fire. Same class of bug, and same shape, as
-- rev_20260921_40_ranger_dead_procs.sql's nine sibling fixes; this record was missed by that pass.
-- ProcFlags 340 = PROC_FLAG_DONE_MELEE_AUTO_ATTACK(0x4) | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS(0x10) |
-- PROC_FLAG_DONE_RANGED_AUTO_ATTACK(0x40) | PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS(0x100) - any direct melee
-- or ranged damage done, matching "when they deal direct damage" with no SpellFamily restriction (537248's
-- EffectSpellClassMask is all-zero). Chance stays 0 so the record's own ProcChance (100) applies, per
-- rev_20260919_20_coa_proc_chance_parity.sql.
DELETE FROM `spell_proc` WHERE `SpellId` = 537248;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(537248, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 0, 0);
