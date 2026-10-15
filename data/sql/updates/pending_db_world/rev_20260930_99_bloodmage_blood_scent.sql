DELETE FROM `spell_proc` WHERE `SpellId` = 804223;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(804223, 0, 0, 0, 0, 0, 69972, 1, 2, 0, 2, 1, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 804223 AND
`ScriptName` = 'aura_ascension_bloodmage_blood_scent';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(804223, 'aura_ascension_bloodmage_blood_scent');
