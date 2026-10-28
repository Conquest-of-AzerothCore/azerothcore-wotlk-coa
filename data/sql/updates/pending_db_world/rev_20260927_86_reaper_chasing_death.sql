-- Chasing Death 707455: its PROC_TRIGGER_SPELL aura has DBC ProcFlags 0, so it never applied the 807418
-- extender aura. Proc on a landed Deathchaser (SpellFamilyName 36, SpellFamilyFlags[0] 0x4, every rank).
DELETE FROM `spell_proc` WHERE `SpellId` = 707455;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (707455, 0, 36, 4, 0, 0, 16, 7, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 807546
  AND `ScriptName` = 'spell_ascension_reaper_chasing_death_extender';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(807546, 'spell_ascension_reaper_chasing_death_extender');
