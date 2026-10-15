--
-- Eternally Chosen (#3292): two Spirits of Life for a Spirit Charge or Primal Rush cast.
DELETE FROM `spell_proc` WHERE `SpellId` = 802888;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(802888, 0, 37, 16384, 131072, 0, 69904, 7, 1, 0, 0, 0, 0, 100, 0, 0);
SET @ScriptName = 'aura_ascension_eternally_chosen';
DELETE FROM `spell_script_names` WHERE `spell_id` = 802888 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (802888, @ScriptName);
SET @ScriptName = 'spell_ascension_primordial_spirit';
DELETE FROM `spell_script_names` WHERE `spell_id` = 572826 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (572826, @ScriptName);
