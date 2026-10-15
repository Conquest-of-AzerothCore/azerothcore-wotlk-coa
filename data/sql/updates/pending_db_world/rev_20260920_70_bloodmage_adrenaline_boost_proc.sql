-- Adrenaline Boost (680675), second clause: "melee critical strikes now have a $h% chance to make your
-- next Dark Liturgy or Bloodmoon Blast instant cast." Effect 1 is aura 42 (proc trigger spell) on
-- Adrenaline 680678, whose only effect is ADD_PCT_MODIFIER / SPELLMOD_CASTING_TIME -100% restricted to
-- the Bloodmoon Blast + Dark Liturgy mask (0, 10240, 0), StackAmount 1 - exactly "your next ... is
-- instant cast". Spell.dbc gives 680675 ProcFlags 0, and SpellMgr::LoadSpellProcs skips auto-generating
-- an entry for a record without proc flags, so Aura::GetProcEffectMask returned 0 and the aura could
-- never fire. Same shape as the merged Blood Rush fix (rev_20260917_80).
-- ProcFlags 20 = PROC_FLAG_DONE_MELEE_AUTO_ATTACK (0x4) | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS (0x10):
-- "melee critical strikes" covers both white swings and melee-class abilities, and nothing else.
-- HitMask 2 = PROC_HIT_CRITICAL, the tooltip's own restriction; the default DONE set would also accept
-- normal and absorbed hits. SpellTypeMask 1 (damage) and SpellPhaseMask 2 (hit) are the usual pair for a
-- damage-done proc. Chance 50 is the record's own ProcChance, which is what $h renders. The record and
-- the tooltip state no internal cooldown and no charge count, so Cooldown and Charges stay 0.
-- The first clause (conditional critical strike chance above 75% / below 35% health) is carried by
-- effects 0 and 2 and is not a proc; it is fixed separately in the module's reviewed selector conversion.
DELETE FROM `spell_proc` WHERE `SpellId` = 680675;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680675, 0, 0, 0, 0, 0, 20, 1, 2, 2, 0, 0, 0, 50, 0, 0);
