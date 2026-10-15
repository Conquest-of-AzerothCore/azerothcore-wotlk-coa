--
-- Tremors (#2183): one periodic-damage roll resets all Seismic cooldowns and grants one free cast.
DELETE FROM `spell_proc` WHERE `SpellId` IN (574323, 562312);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(574323, 0, 0, 0, 0, 0, 262144, 1, 2, 3, 2, 0, 0, 10, 0, 0),
(562312, 0, 37, 80, 4194304, 262144, 69904, 7, 1, 0, 0, 0, 0, 100, 0, 1);
SET @ScriptName = 'aura_ascension_primalist_periodic_damage';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (574323) AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(574323, @ScriptName);
