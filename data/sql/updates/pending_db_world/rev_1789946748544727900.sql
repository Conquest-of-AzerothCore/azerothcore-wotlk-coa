--
-- Druid Training (#3136): each Geode damage event heals nearby allies for ten percent.
DELETE FROM `spell_proc` WHERE `SpellId` = 707560;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(707560, 0, 37, 4096, 0, 0, 332048, 1, 2, 3, 2, 3, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 707560 AND `ScriptName` = 'aura_ascension_druid_training';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (707560, 'aura_ascension_druid_training');
