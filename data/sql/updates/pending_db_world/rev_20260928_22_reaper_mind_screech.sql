-- Mind Screech 705448 ships ProcFlags 0. Live Shrieking Scythe is the client's Soulrend (every rank carries
-- SpellFamilyFlags[1] 0x2000), so the talent procs on a landed Soulrend with the flags Soulstorm uses for the same
-- spell. Its script casts 802086 (silence and weapon damage) with the 200% scaled by the Reaper's missing health,
-- and skips silence-immune targets.
DELETE FROM `spell_proc` WHERE `SpellId` = 705448;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (705448, 0, 36, 0, 8192, 0, 69652, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 705448 AND `ScriptName` = 'aura_ascension_reaper_mind_screech';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(705448, 'aura_ascension_reaper_mind_screech');
