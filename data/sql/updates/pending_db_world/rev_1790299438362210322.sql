--
DELETE FROM `spell_script_names` WHERE `spell_id` = 803997 AND `ScriptName` = 'aura_ascension_ghostly_weapon';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (803997, 'aura_ascension_ghostly_weapon');

DELETE FROM `spell_proc` WHERE `SpellId` = 803997;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(803997, 0, 0, 0, 0, 0, 20, 1, 2, 3, 0, 6, 0, 100, 0, 0);
