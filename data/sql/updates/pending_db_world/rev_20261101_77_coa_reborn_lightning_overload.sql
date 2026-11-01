-- Reborn Lightning Overload casts the Reborn overloads 1145284/1145297 (named Lightning Bolt and Chain Lightning, so no
-- twin of the stock overloads) at its tooltip's half chance, instead of the stock script's stock overloads.
DELETE FROM `spell_script_names` WHERE `spell_id` = -1130675 AND `ScriptName` IN ('spell_sha_lightning_overload',
'spell_ascension_reborn_lightning_overload');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-1130675, 'spell_ascension_reborn_lightning_overload');
