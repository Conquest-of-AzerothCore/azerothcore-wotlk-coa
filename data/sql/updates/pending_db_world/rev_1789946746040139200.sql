--
-- Empowered Boons (#3063): one matching boon per Totemic Smash cast.
DELETE FROM `spell_proc` WHERE `SpellId` = 706340;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706340, 0, 37, 0, 0, 16, 69904, 1, 1, 0, 2, 0, 0, 100, 0, 0);
SET @ScriptName = 'aura_ascension_empowered_boons';
DELETE FROM `spell_script_names` WHERE `spell_id` = 706340 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (706340, @ScriptName);
SET @ScriptName = 'spell_ascension_empowered_hawk';
DELETE FROM `spell_script_names` WHERE `spell_id` = 523526 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (523526, @ScriptName);
SET @ScriptName = 'spell_ascension_empowered_wolf';
DELETE FROM `spell_script_names` WHERE `spell_id` = 523527 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (523527, @ScriptName);
