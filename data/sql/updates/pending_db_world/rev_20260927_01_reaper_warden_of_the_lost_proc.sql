-- Issue #683: Warden of the Lost (707116) applies a SPELL_EFFECT_ASCENSION_APPLY_AURA_TO_SUMMONS(190)
-- aura to the Reaper's owned summons (Spectral Scythes/Wardens). That aura's own effect 0 is a native
-- SPELL_AURA_PROC_TRIGGER_SPELL(42) triggering 707128 on the summon's own damage-dealt events, but
-- Spell.dbc has ProcFlags=0 for 707116 and no spell_proc row existed, so LoadSpellProcs never built an
-- entry and the applied aura never saw a proc event. 707116's own ProcChance is 100 in Spell.dbc.
DELETE FROM `spell_proc` WHERE `SpellId` = 707116;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (707116, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 0, 0, 0, 100, 0, 0);
