--
-- Lithic Lance (#3010): resource proc, temporary replacement and successful-cast consumption.
SET @ScriptName = 'aura_ascension_lithic_lance_talent';
DELETE FROM `spell_script_names` WHERE `spell_id` = 706159 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (706159, @ScriptName);
SET @ScriptName = 'aura_ascension_lithic_lance_ready';
DELETE FROM `spell_script_names` WHERE `spell_id` = 807048 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (807048, @ScriptName);
SET @ScriptName = 'spell_ascension_lithic_lance';
DELETE FROM `spell_script_names` WHERE `spell_id` = 681251 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (681251, @ScriptName);
