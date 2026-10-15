--
-- Running on Instinct (#1759): heal allies in the Rush line and grant one stack per ally.
SET @ScriptName = 'spell_ascension_running_instinct';
DELETE FROM `spell_script_names` WHERE `spell_id` = -500696 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (-500696, @ScriptName);
SET @ScriptName = 'spell_ascension_running_instinct_heal';
DELETE FROM `spell_script_names` WHERE `spell_id` = 301203 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (301203, @ScriptName);
DELETE FROM `spell_bonus_data` WHERE `entry` = 301203;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`)
VALUES (301203, 0.35, 0, 0.25, 0, 'Running on Instinct: 35% healing power and 25% attack power');
