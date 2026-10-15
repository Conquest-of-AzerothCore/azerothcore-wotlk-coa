--
-- Totem Warrior (#749): repeat 40% of each completed Wildclaw weapon hit while Boon of the Bear is active.
SET @ScriptName = 'spell_ascension_totem_warrior';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (-800140, 504240) AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (-800140, @ScriptName), (504240, @ScriptName);
