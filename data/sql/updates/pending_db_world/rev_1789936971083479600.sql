--
-- Judgement of the Three Hammers (#1950): direct damage procs three hammers without recursion.
DELETE FROM `spell_proc` WHERE `SpellId` = 520466;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(520466, 0, 0, 0, 0, 0, 69972, 1, 2, 3, 2, 0, 0, 20, 0, 0);
SET @ScriptName = 'aura_ascension_primalist_judgement';
DELETE FROM `spell_script_names` WHERE `spell_id` = 520466 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (520466, @ScriptName);
DELETE FROM `spell_bonus_data` WHERE `entry` = 520468;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`)
VALUES (520468, 0.325, 0, 0.278, 0, 'Judgement of the Three Hammers: 32.5% SP and 27.8% AP');
