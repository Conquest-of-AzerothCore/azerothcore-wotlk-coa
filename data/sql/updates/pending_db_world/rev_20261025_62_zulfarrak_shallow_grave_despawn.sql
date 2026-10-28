-- COA-7110: Shallow Grave 128403 in Zul'Farrak summoned its zombies and stayed, so it could be opened again and
-- again. Like Shallow Grave 128308, it now despawns after it is opened.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 128403 AND `source_type` = 1 AND `id` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
    `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`,
    `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(128403, 1, 1, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 2000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Shallow Grave - On Gossip Hello - Despawn');
