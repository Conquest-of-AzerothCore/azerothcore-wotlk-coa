DELETE FROM `spell_script_names` WHERE `spell_id` = 806723 AND `ScriptName` = 'aura_ascension_bloodmage_shadow_colony';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(806723, 'aura_ascension_bloodmage_shadow_colony');

DELETE FROM `spell_proc` WHERE `SpellId` = 806723;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(806723, 0, 0, 0, 0, 0, 139944, 1, 2, 0, 0, 0, 0, 0, 5000, 0);
