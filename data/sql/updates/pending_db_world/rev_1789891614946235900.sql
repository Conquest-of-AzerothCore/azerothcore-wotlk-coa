--
-- Fury of the Earthmother (#631): Geode damage has a 15% chance to replenish an active Rock Barrier.
DELETE FROM `spell_proc` WHERE `SpellId` = 680412;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680412, 0, 37, 4096, 32, 0, 65536, 1, 2, 3, 2, 1, 0, 15, 0, 0);

SET @ScriptName = 'aura_ascension_fury_of_earthmother';
DELETE FROM `spell_script_names` WHERE `spell_id` = 680412 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(680412, @ScriptName);

SET @ScriptName = 'spell_ascension_fury_of_earthmother_charge';
DELETE FROM `spell_script_names` WHERE `spell_id` = 520134 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(520134, @ScriptName);
