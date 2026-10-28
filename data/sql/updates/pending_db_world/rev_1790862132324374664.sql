DELETE FROM `spell_script_names` WHERE `spell_id` = 800077 AND `ScriptName` = 'aura_ascension_ranger_barbed_quills';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (800077, 'aura_ascension_ranger_barbed_quills');

DELETE FROM `spell_proc` WHERE `SpellId` = 800077;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(800077, 0, 27, 0, 131332, 0, 272, 1, 2, 0, 2, 6, 0, 0, 0, 0);
