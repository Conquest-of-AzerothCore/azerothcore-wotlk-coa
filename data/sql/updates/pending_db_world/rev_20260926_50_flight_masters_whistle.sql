-- Flight Master's Whistle (item 10, spell 158): "Call in a ride and Retreat to one of the nearest Flightmasters!".
-- The spell is a single dummy effect with no script, so using the whistle did nothing. spell_ascension_flight_masters_whistle
-- teleports the player to the nearest flight master of their faction on the current continent (and refuses the cast
-- inside instances or where no reachable flight master exists).
DELETE FROM `spell_script_names` WHERE `spell_id` = 158 AND `ScriptName` = 'spell_ascension_flight_masters_whistle';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (158, 'spell_ascension_flight_masters_whistle');
