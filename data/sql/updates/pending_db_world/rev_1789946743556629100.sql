--
-- Primal Strikes (#3015): physical ability critical damage grants three Rage; auto-attacks are excluded.
DELETE FROM `spell_proc` WHERE `SpellId` = 706171;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706171, 1, 0, 0, 0, 0, 332048, 1, 2, 2, 2, 0, 0, 100, 0, 0);
SET @ScriptName = 'aura_ascension_primal_strikes';
DELETE FROM `spell_script_names` WHERE `spell_id` = 706171 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (706171, @ScriptName);
