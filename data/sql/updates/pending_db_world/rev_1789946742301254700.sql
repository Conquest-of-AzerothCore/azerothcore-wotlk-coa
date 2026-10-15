--
-- Earth's Guidance (#2995): positive Seismic damage/healing reduces every active Seismic cooldown.
DELETE FROM `spell_proc` WHERE `SpellId` = 706138;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706138, 0, 37, 80, 4194560, 263168, 349456, 3, 2, 3, 2, 0, 0, 20, 0, 0);
SET @ScriptName = 'aura_ascension_earths_guidance';
DELETE FROM `spell_script_names` WHERE `spell_id` = 706138 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (706138, @ScriptName);
