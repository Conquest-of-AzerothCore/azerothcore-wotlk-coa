-- Zul'Farrak: Shallow Grave 128308 summoned its zombies once (row 0) but its despawn row had no target (target_type 0),
-- so it never despawned and could be opened again and again (#4338). It now despawns one minute after it is opened,
-- which leaves time to take its loot; row 0 is unchanged.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 128308 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(128308, 1, 0, 0, 64, 0, 100, 257, 0, 0, 0, 0, 0, 0, 11, 10247, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Shallow Grave - On Gossip Hello - Cast Summon Zul''Farrak Zombies'),
(128308, 1, 1, 0, 64, 0, 100, 257, 0, 0, 0, 0, 0, 0, 41, 60000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Shallow Grave - On Gossip Hello - Despawn in 1 min');
