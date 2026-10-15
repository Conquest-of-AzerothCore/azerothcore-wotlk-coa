-- Guardbreaker rank 2 (681493): its effect 1 casts the Pommel Smash debuff on a proc, but the spell has no DBC
-- ProcFlags and SpellMgr does not generate a proc entry without them. Proc on Pommel Smash's class mask (word2
-- 0x2000000), melee spell class (PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS 0x10), on the hit phase.
DELETE FROM `spell_proc` WHERE `SpellId` = 681493;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(681493, 0, 21, 0, 0, 33554432, 16, 0, 2, 0, 0, 0, 0, 100, 0, 0);
