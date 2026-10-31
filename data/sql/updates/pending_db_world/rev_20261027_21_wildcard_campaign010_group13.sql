START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` IN (44543, 44545) AND `ScriptName` = 'aura_wildcard_fingers_light_consumption';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(44543, 'aura_wildcard_fingers_light_consumption'),
(44545, 'aura_wildcard_fingers_light_consumption');
COMMIT;
