-- Bind one Gargolmar room per Manastorm track to the native Ramparts patrol.
START TRANSACTION;

DELETE FROM `game_tele`
WHERE `id` = 19646 AND `name` = 'Manastorm_Ramparts_Gargolmar';

INSERT INTO `game_tele` (`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`)
VALUES (19646, -1216.89, 1545.05, 68.6415, 5.826, 543, 'Manastorm_Ramparts_Gargolmar');

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19646,
    `chaotic_link_stacks` = 2,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE `map_id` = 543 AND `objective_creature_entry` = 17306
  AND ((`segment_id` = 751 AND `difficulty` = 0 AND `dungeon_encounter_id` = 392)
    OR (`segment_id` = 862 AND `difficulty` = 2 AND `dungeon_encounter_id` = 915));

DELETE FROM `manastorm_segment_spawn`
WHERE `segment_id` IN (751, 862) AND `spawn_guid` IN (202695, 202696);

INSERT INTO `manastorm_segment_spawn` (`segment_id`, `spawn_guid`, `flags`, `enabled`)
SELECT `s`.`segment_id`, `c`.`guid`, 3, 1
FROM `manastorm_segment` AS `s`
JOIN `creature` AS `c` ON `c`.`map` = 543 AND `c`.`id` = 17309 AND (`c`.`spawnMask` & 5) = 5
WHERE `s`.`segment_id` IN (751, 862) AND `s`.`start_game_tele_id` = 19646
  AND `c`.`guid` IN (202695, 202696);

COMMIT;
