--
-- Protector of the Grove (#579): every direct damaging event reduces each named cooldown by one second.
DELETE FROM `spell_proc` WHERE `SpellId` = 504198;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504198, 0, 0, 0, 0, 0, 69972, 1, 2, 3, 2, 0, 0, 100, 0, 0);

SET @ScriptName = 'aura_ascension_primalist_direct_damage';
DELETE FROM `spell_script_names` WHERE `spell_id` = 504198 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (504198, @ScriptName);

SET @ScriptName = 'spell_ascension_protector_of_the_grove';
DELETE FROM `spell_script_names` WHERE `spell_id` = 504199 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (504199, @ScriptName);
