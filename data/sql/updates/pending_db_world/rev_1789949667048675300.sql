--
-- Rylaks Blessing (#3289): positive Rylak damage grants two pet-only damage/critical stacks.
DELETE FROM `spell_proc` WHERE `SpellId` = 802595;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(802595, 0, 37, 0, 0, 64, 332048, 1, 2, 3, 2, 0, 0, 100, 0, 0);
SET @ScriptName = 'aura_ascension_rylaks_blessing';
DELETE FROM `spell_script_names` WHERE `spell_id` = 802595 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (802595, @ScriptName);
SET @ScriptName = 'aura_ascension_rylaks_blessing_pet';
DELETE FROM `spell_script_names` WHERE `spell_id` = 802596 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (802596, @ScriptName);
