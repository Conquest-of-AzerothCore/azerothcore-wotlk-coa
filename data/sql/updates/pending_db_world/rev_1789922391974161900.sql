--
-- Dream (#1298): cover both native Earthshaping stack-gain helpers.
SET @ScriptName = 'spell_ascension_primalist_earthshaping_gain';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (681072, 681264) AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(681072, 'spell_ascension_primalist_earthshaping_gain'),
(681264, 'spell_ascension_primalist_earthshaping_gain');
