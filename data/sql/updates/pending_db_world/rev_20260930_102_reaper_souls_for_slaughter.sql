DELETE FROM `spell_proc` WHERE `SpellId` = 504304;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504304, 0, 0, 0, 0, 0, 4, 1, 2, 0, 2, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 504304 AND
`ScriptName` = 'aura_ascension_reaper_souls_for_slaughter';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(504304, 'aura_ascension_reaper_souls_for_slaughter');
