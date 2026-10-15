-- Fog (806100) leaves an 8 yd ground area for 8 seconds; the script records that area so hostile casts
-- crossing its edge are refused.
DELETE FROM `spell_script_names` WHERE `spell_id` = 806100 AND `ScriptName` = 'spell_ascension_stormbringer_fog';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (806100, 'spell_ascension_stormbringer_fog');
