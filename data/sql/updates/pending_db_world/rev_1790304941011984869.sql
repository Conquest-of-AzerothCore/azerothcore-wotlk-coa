--
DELETE FROM `spell_proc` WHERE `SpellId` = 301193;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (301193, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 2, 0, 0, 8, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 500618
  AND `ScriptName` = 'spell_reaper_beyond_death_bolt';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500618, 'spell_reaper_beyond_death_bolt');
