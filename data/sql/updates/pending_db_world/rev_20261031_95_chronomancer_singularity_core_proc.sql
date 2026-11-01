-- #10383 Singularity Core 804438 never procs from wand attacks or wand spells
--
-- 804438's aura-42 effect (index 0, trigger 804437) has an empty EffectSpellClassMask, so it should be a
-- wildcard proc. SpellMgr::LoadSpellProcs builds the default proc entry from every effect whose aura is a
-- trigger aura, and it ORs their EffectSpellClassMask: Singularity Core's effects 1 and 2 are
-- SPELL_AURA_ADD_PCT_MODIFIER (aura 108, the Shatter Echo damage bonus) with mask (0, 0, 16), so the
-- generated entry ends up SpellFamilyName 28 / mask (0, 0, 16). CanSpellTriggerProcOnEvent then requires
-- the damaging spell's SpellFamilyFlags to intersect that mask: Wand of Time 520175 (family flags
-- 16781312, 1048576, 0) and Artificer's Wand damage 561064 (0, 0, 512) do not, so every wand spell is
-- filtered out and 804437 never casts. Only auto attacks slip through (their event has no spell info, so
-- the family check is skipped), which is why the #8111 in-game check passed on auto attacks while the class
-- still reports "doesn't proc" for Artificer skills (#9163, #9542, #10383).
--
-- The explicit row restores what the DBC already says - the proc aura's own class mask is empty, so the
-- proc stays a wildcard, on the DBC ProcFlags (0x4001C0: ranged auto attack 0x40, taken ranged auto attack
-- 0x80, done ranged-class spell damage 0x100, main-hand attack 0x400000) and 100% chance - and stops the
-- default generator from running for this spell.
START TRANSACTION;

DELETE FROM `spell_proc` WHERE `SpellId` = 804438;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(804438, 0, 0, 0, 0, 0, 4194752, 1, 2, 0, 0, 0, 0, 100, 0, 0);

COMMIT;
