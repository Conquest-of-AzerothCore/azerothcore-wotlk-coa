DELETE FROM `spell_script_names`
WHERE (`spell_id` = -800156 AND `ScriptName` = 'spell_ascension_bloodmage_bloodfang_bite')
OR (`spell_id` = 706654 AND `ScriptName` = 'aura_ascension_bloodmage_bite_wound');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-800156, 'spell_ascension_bloodmage_bloodfang_bite'),
(706654, 'aura_ascension_bloodmage_bite_wound');

DELETE FROM `spell_proc` WHERE `SpellId` = 706654;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706654, 0, 0, 0, 0, 0, 136, 0, 0, 0, 0, 0, 0, 100, 0, 0);
