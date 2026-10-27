-- #8544: Counterattack! only started once per restart. Actionlist 338900 ends with a 2-hour wait (row 27), so a
-- later accept found it still running and SMART_ACTION_CALL_TIMED_ACTIONLIST refused to start the next wave.
-- The accept and gossip rows (3, 8) now allow the new run to replace the pending one (action_param3 = 1).
DELETE FROM `smart_scripts` WHERE `entryorguid` = 3389 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(3389, 0, 1, 0, 11, 0, 100, 512, 0, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Regthar Deathgate - On Spawn  - Set Phase 1 '),
(3389, 0, 2, 3, 19, 1, 100, 0, 4021, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Regthar Deathgate - On quest accept  - say text 0 '),
(3389, 0, 3, 4, 61, 1, 100, 512, 0, 0, 0, 0, 0, 0, 80, 338900, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Regthar Deathgate - Linked with Previous Event -  Run script (Allow Override)'),
(3389, 0, 4, 0, 61, 1, 100, 512, 0, 0, 0, 0, 0, 0, 22, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Regthar Deathgate - Linked with Previous Event -  Set Phase 2'),
(3389, 0, 5, 0, 1, 0, 100, 512, 300000, 300000, 300000, 300000, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Regthar Deathgate - OOC (P2)  - Set Phase 1 '),
(3389, 0, 6, 0, 20, 0, 100, 512, 4021, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Regthar Deathgate - On quest Reward  - Set Phase 1 '),
(3389, 0, 7, 8, 62, 1, 100, 0, 1882, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Regthar Deathgate - On Gossip Option Select  - say text 0 '),
(3389, 0, 8, 9, 61, 1, 100, 512, 0, 0, 0, 0, 0, 0, 80, 338900, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Regthar Deathgate - Linked with Previous Event -  Run script (Allow Override)'),
(3389, 0, 9, 0, 61, 1, 100, 512, 0, 0, 0, 0, 0, 0, 22, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Regthar Deathgate - Linked with Previous Event -  Set Phase 2'),
(3389, 0, 10, 0, 62, 0, 100, 512, 1882, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Regthar Deathgate - On Gossip Option Select  - Close Gossip ');
