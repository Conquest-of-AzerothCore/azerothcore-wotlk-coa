-- #8204, #9460: the Flight Master's Whistle offers the 3 nearest flight masters, then casts the 10 s whistle teleport.
UPDATE `item_template` SET `ScriptName` = 'item_ascension_flight_masters_whistle' WHERE `entry` = 10;

DELETE FROM `spell_script_names` WHERE `spell_id` = 2485 AND `ScriptName` = 'spell_ascension_flight_masters_whistle_teleport';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2485, 'spell_ascension_flight_masters_whistle_teleport');

DELETE FROM `npc_text` WHERE `ID` = 9990158;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES
(9990158, 'Choose between the 3 closest Flightmasters below to teleport to that location.', 'Choose between the 3 closest Flightmasters below to teleport to that location.', 1);
