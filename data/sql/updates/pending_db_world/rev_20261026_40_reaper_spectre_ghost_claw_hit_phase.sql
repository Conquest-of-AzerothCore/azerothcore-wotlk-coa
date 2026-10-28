-- Spectre (561170): the proc watching Withering Touch (573071) must fire at hit phase, not
-- cast phase. At cast phase Spell::cast() passes a null action target to ProcSkillsAndAuras
-- (PROC_SPELL_PHASE_CAST), so AuraEffect::HandleProcTriggerSpellAuraProc casts Ghost Claw
-- (803985) at a null target and fails (SPELL_FAILED_BAD_TARGETS). Hit phase resolves the real
-- touched target.
DELETE FROM `spell_proc` WHERE `SpellId` = 561170;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (561170, 0, 0, 0, 0, 0, 87060, 7, 2, 0, 0, 0, 0, 100, 0, 0);
