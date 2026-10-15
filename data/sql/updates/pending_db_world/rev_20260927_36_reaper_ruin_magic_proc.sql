-- Ruin (805198) still never triggers from Murder (500376): the CheckProc allowlist now covers
-- Murder's rank chain, but the spell_proc row's ProcFlags (262160 = PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS
-- | PROC_FLAG_DONE_PERIODIC) only admits melee-class hits and periodic ticks. Murder is
-- SPELL_DAMAGE_CLASS_MAGIC (Spell.dbc DmgClass=1) and a direct, non-periodic negative cast, so the
-- event never reaches SpellMgr::LoadSpellProcs' proc mask and CheckProc is never called for it.
-- Add PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG (0x10000) so a direct magic-class hit also qualifies:
-- 262160 | 0x10000 = 327696. Shudder Scythe's own periodic route (801322's separate
-- spell_ascension_reaper_ruin_mark SpellScript) is unaffected by this table.
DELETE FROM `spell_proc` WHERE `SpellId` = 805198;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (805198, 0, 0, 0, 0, 0, 327696, 1, 2, 0, 0, 0, 0, 100, 0, 0);
