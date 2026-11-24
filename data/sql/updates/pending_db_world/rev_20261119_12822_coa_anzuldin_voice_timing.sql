-- Anzuldin (164806): wait for each voiced line of Voice of the Snow Loa (175155) to end before the next one
DELETE FROM `smart_scripts` WHERE (`entryorguid`, `source_type`) IN ((164806, 0));
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164806, 0, 0, 0, 19, 0, 100, 0, 175155, 0, 0, 0, 0, 0, 1, 0, 10000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Anzuldin - On Quest Accepted Voice of the Snow Loa - Say Line 0 (loa1.wav 8.7 s)'),
(164806, 0, 1, 0, 52, 0, 100, 0, 0, 164806, 0, 0, 0, 0, 1, 1, 11000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Anzuldin - On Text 0 Over - Say Line 1 (loa2.wav 9.9 s)'),
(164806, 0, 2, 0, 52, 0, 100, 0, 1, 164806, 0, 0, 0, 0, 1, 2, 7000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Anzuldin - On Text 1 Over - Say Line 2 (loa3.wav 3.9 s)'),
(164806, 0, 3, 0, 52, 0, 100, 0, 2, 164806, 0, 0, 0, 0, 1, 3, 12000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Anzuldin - On Text 2 Over - Say Line 3 (loa4.wav 10.2 s)'),
(164806, 0, 4, 0, 52, 0, 100, 0, 3, 164806, 0, 0, 0, 0, 1, 4, 10000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Anzuldin - On Text 3 Over - Say Line 4 (loa5.wav 8.9 s)'),
(164806, 0, 5, 0, 52, 0, 100, 0, 4, 164806, 0, 0, 0, 0, 1, 5, 15000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Anzuldin - On Text 4 Over - Say Line 5 (loa6.wav 13.1 s)'),
(164806, 0, 6, 0, 52, 0, 100, 0, 5, 164806, 0, 0, 0, 0, 1, 6, 7000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Anzuldin - On Text 5 Over - Say Line 6 (loa7.wav 4.8 s)'),
(164806, 0, 7, 0, 52, 0, 100, 0, 6, 164806, 0, 0, 0, 0, 33, 164806, 0, 0, 0, 0, 0, 17, 0, 25, 0, 0, 0, 0, 0, 0, 'Anzuldin - On Text 6 Over - Quest Credit Anzuldin questioned (175155) to every player in earshot'),
(164806, 0, 8, 9, 10, 0, 100, 0, 1, 20, 10000, 10000, 1, 0, 33, 164806, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Anzuldin - Player within 20 yd - Quest Credit Altar of the Loa found (175154)'),
(164806, 0, 9, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 84, 7, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Anzuldin - Linked - Say Line 7 (simple talk, leaves the speech timer alone)'),
(164806, 0, 10, 11, 62, 0, 100, 0, 100725, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Anzuldin - On Gossip Option 0 Selected - Close Gossip'),
(164806, 0, 11, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, -6663.41, 376.68, 697.51, 0.56, 'Anzuldin - Linked - Teleport back to the Crippled Peak altar');
