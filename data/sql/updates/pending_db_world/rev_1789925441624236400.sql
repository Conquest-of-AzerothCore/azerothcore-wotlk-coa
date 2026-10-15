--
-- Earthshaker (#1732): physical Seismic periodic damage uses Nature spell critical chance.
SET @ScriptName = 'aura_ascension_earthshaker_periodic';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (-803981, -680442) AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (-803981, @ScriptName), (-680442, @ScriptName);
