--
DELETE FROM `spell_proc` WHERE `SpellId` = 572213;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(572213, 0, 0, 0, 0, 0, 69972, 1, 2, 2, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 572213 AND `ScriptName` = 'aura_ascension_gravesite';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(572213, 'aura_ascension_gravesite');
