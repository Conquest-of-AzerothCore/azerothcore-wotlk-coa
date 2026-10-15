--
-- Wildheart (#3332): remaining cooldown reductions and missing-resource recovery.
SET @ScriptName = 'aura_ascension_wildheart';
DELETE FROM `spell_script_names` WHERE `spell_id` = 803980 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (803980, @ScriptName);
SET @ScriptName = 'spell_ascension_wildheart_recovery';
DELETE FROM `spell_script_names` WHERE `spell_id` = 810040 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (810040, @ScriptName);
DELETE FROM `spell_bonus_data` WHERE `entry` = 810040;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(810040, 0, 0, 0, 0, 'Wildheart: five percent of missing resources');
