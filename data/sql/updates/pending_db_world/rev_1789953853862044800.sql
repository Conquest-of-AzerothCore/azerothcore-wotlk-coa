--
-- Neptulon's Wrath (#3698): allied direct damage procs the caster's snapshotted 35% AP.
DELETE FROM `spell_proc` WHERE `SpellId` = 537250;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(537250, 0, 0, 0, 0, 0, 69972, 1, 2, 3, 2, 0, 0, 100, 0, 0);
SET @ScriptName = 'spell_ascension_neptulon_wrath';
DELETE FROM `spell_script_names` WHERE `spell_id` = 807467 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (807467, @ScriptName);
SET @ScriptName = 'aura_ascension_neptulon_wrath';
DELETE FROM `spell_script_names` WHERE `spell_id` = 537250 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (537250, @ScriptName);
DELETE FROM `spell_bonus_data` WHERE `entry` = 537252;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(537252, 0, 0, 0, 0, 'Neptulon Wrath: forwarded caster AP, no second coefficient');
