-- Path to Ascension: Westfall (100466), #10103: talking to Dungar Longdrink only granted quest credit, never
-- activating the Stormwind -> Sentinel Hill taxi connection the quest text promises. TaxiPath.dbc record 6
-- (From=2 "Stormwind, Elwynn", To=4 "Sentinel Hill, Westfall") is the direct flight; link the existing gossip
-- credit to a new SMART_ACTION_ACTIVATE_TAXI row.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 352 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(352, 0, 0, 1, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 9526, 4, 30000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dungar Longdrink - On Aggro - Summon Creature ''Enraged Gryphon'''),
(352, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 9526, 4, 30000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dungar Longdrink - On Aggro - Summon Creature ''Enraged Gryphon'''),
(352, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dungar Longdrink - On Aggro - Say Line 0'),
(352, 0, 3, 4, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 100467, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dungar Longdrink - On Gossip Hello - Quest Credit ''Path to Ascension: Westfall'''),
(352, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 52, 6, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dungar Longdrink - On Link - Activate Taxi Path 6 (Stormwind -> Westfall)');
