--
-- Totemic Echoes (#1887): only a normal Totemic Smash schedules a two-second echo.
DELETE FROM `spell_proc` WHERE `SpellId` = 500937;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(500937, 0, 37, 0, 0, 16, 16, 1, 2, 3, 0, 0, 0, 100, 0, 0);
SET @ScriptName = 'aura_ascension_totemic_echoes';
DELETE FROM `spell_script_names` WHERE `spell_id` = 547213 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (547213, @ScriptName);
