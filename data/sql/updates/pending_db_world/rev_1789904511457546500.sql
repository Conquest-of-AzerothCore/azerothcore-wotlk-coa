--
-- Rupturer (#645): all Seismic damage grants Geomolding; critical hits add Geomolding and Earthshaping.
DELETE FROM `spell_proc` WHERE `SpellId` IN (706208, 707228);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706208, 0, 37, 16, 4194304, 0, 327680, 1, 2, 3, 2, 4, 0, 100, 0, 0),
(707228, 0, 37, 16, 4194304, 0, 327680, 1, 2, 2, 2, 4, 0, 100, 0, 0);

DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 706208 AND `spell_effect` = 707228 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(706208, 707228, 2, 'Rupturer - extra critical-strike resource stacks');

SET @ScriptName = 'spell_ascension_rupturer_lance';
DELETE FROM `spell_script_names` WHERE `spell_id` = 681354 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (681354, @ScriptName);
