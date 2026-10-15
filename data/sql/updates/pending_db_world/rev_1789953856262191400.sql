--
-- Ancient of War (#3710): tie the authored movement penalty to the active transformation.
SET @ScriptName = 'aura_ascension_ancient_war';
DELETE FROM `spell_script_names` WHERE `spell_id` = 504222 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (504222, @ScriptName);
