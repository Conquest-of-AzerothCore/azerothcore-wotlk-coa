DELETE FROM `spell_proc` WHERE `SpellId` = 572768;
INSERT INTO `spell_proc`
  (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`)
VALUES
  (572768, 332116, 1, 2, 3, 2, 100);

DELETE FROM `spell_script_names` WHERE `spell_id` = 572768
  AND `ScriptName` = 'aura_ascension_reaper_siphon_anima';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
  (572768, 'aura_ascension_reaper_siphon_anima');
