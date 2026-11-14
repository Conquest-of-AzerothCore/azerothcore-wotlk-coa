DELETE FROM `spell_proc` WHERE `SpellId` = 681311;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(681311, 0, 0, 0, 0, 0, 1048575, 7, 2, 32767, 2, 0, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 681311 AND `ScriptName` = 'aura_ascension_tinker_event';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(681311, 'aura_ascension_tinker_event');
