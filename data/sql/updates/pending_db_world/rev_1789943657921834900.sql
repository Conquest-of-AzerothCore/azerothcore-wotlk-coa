--
-- Quaking Thane (#2040): count distinct Quake victims and successful Mountain Hammer casts.
SET @ScriptName = 'spell_ascension_quaking_thane';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (-803974, -681130) AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-803974, @ScriptName),
(-681130, @ScriptName);
SET @ScriptName = 'aura_ascension_thanes_rage';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (804124) AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(804124, @ScriptName);
