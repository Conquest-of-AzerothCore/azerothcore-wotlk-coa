--
-- Mountain Avatar (#3139): one five-percent grant or extension per Geode damage event.
DELETE FROM `spell_proc` WHERE `SpellId` = 707616;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(707616, 0, 37, 4096, 32, 4096, 332048, 1, 2, 3, 2, 2, 0, 5, 0, 0);
SET @ScriptName = 'aura_ascension_mountain_avatar';
DELETE FROM `spell_script_names` WHERE `spell_id` = 707616 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (707616, @ScriptName);
SET @ScriptName = 'aura_ascension_earthen_avatar';
DELETE FROM `spell_script_names` WHERE `spell_id` = 680421 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (680421, @ScriptName);
