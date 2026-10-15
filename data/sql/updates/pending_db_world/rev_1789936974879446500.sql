--
-- Verdant Chase (#2002): implement the native periodic remaining-cooldown helper.
SET @ScriptName = 'spell_ascension_verdant_chase';
DELETE FROM `spell_script_names` WHERE `spell_id` = 560306 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (560306, @ScriptName);
