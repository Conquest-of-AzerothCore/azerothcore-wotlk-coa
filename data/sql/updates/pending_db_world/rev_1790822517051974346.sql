DELETE FROM `spell_script_names` WHERE `spell_id` = 806229 AND `ScriptName` = 'aura_ascension_ancestral_evolution';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(806229, 'aura_ascension_ancestral_evolution');
DELETE FROM `spell_proc` WHERE `SpellId` = 806229;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(806229, 0, 0, 0, 0, 0, 1048576, 1, 2, 0, 0, 0, 0, 100, 0, 0);
