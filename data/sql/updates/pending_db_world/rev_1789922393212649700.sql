--
-- Heavy Earth (#1316): successful Terrasurge casts consume Earthshaping and grant the damage echo.
DELETE FROM `spell_script_names` WHERE `spell_id` = -681119 AND `ScriptName` = 'spell_ascension_heavy_earth';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (-681119, 'spell_ascension_heavy_earth');
DELETE FROM `spell_script_names` WHERE `spell_id` = 560142 AND `ScriptName` = 'aura_ascension_heavy_earth';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (560142, 'aura_ascension_heavy_earth');
DELETE FROM `spell_proc` WHERE `SpellId` = 560142;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560142, 0, 37, 4096, 512, 0, 87312, 1, 2, 3, 2, 0, 0, 100, 0, 0);
