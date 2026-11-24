-- Enable one authored boss room per Manastorm track on each supported TBC map.
START TRANSACTION;

DELETE FROM `game_tele`
WHERE `id` BETWEEN 19647 AND 19659 AND `name` LIKE 'Manastorm_TBC_%';

INSERT INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`)
VALUES
(19647, 381.09, 56.95, -7.21592, 3.04, 540, 'Manastorm_TBC_Omrogg'),
(19648, 343.419, 102.651, 9.6201, 2, 542, 'Manastorm_TBC_Maker'),
(19649, 82.43, -315.48, -7.78743, 6.18, 545, 'Manastorm_TBC_Thespia'),
(19650, -120.3, -382.72, 36.8659, 4.54, 546, 'Manastorm_TBC_Hungarfen'),
(19651, 12.49, -449.87, 3.0559, 0.24, 547, 'Manastorm_TBC_Rokmar'),
(19652, 257.83, -125.837, -10.0399, 0.18, 552, 'Manastorm_TBC_Zereketh'),
(19653, 151.661, 281.789, -4.33475, 1.62, 553, 'Manastorm_TBC_Sarannis'),
(19654, 202.37, -14.38, -2.11654, 0.22, 554, 'Manastorm_TBC_Capacitus'),
(19655, -322.21, -38.94, 12.6888, 3.16, 555, 'Manastorm_TBC_Blackheart'),
(19656, -102.481, 170.061, 0.0932373, 3.06, 556, 'Manastorm_TBC_Syth'),
(19657, -92.1778, -103.641, -0.746599, 5.72, 557, 'Manastorm_TBC_Pandemonius'),
(19658, -44.91, -163.02, 26.3687, 3.16, 558, 'Manastorm_TBC_Shirrak'),
(19659, 231.68, -208.35, -6.32328, 4.66, 585, 'Manastorm_TBC_Vexallus');

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19647, `chaotic_link_stacks` = 0, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 540 AND `objective_creature_entry` = 16809
  AND ((`segment_id` = 760 AND `difficulty` = 0 AND `dungeon_encounter_id` = 410)
    OR (`segment_id` = 871 AND `difficulty` = 2 AND `dungeon_encounter_id` = 923));

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19648, `chaotic_link_stacks` = 2, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 542 AND `objective_creature_entry` = 17381
  AND ((`segment_id` = 755 AND `difficulty` = 0 AND `dungeon_encounter_id` = 401)
    OR (`segment_id` = 866 AND `difficulty` = 2 AND `dungeon_encounter_id` = 925));

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19649, `chaotic_link_stacks` = 2, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 545 AND `objective_creature_entry` = 17797
  AND ((`segment_id` = 781 AND `difficulty` = 0 AND `dungeon_encounter_id` = 314)
    OR (`segment_id` = 892 AND `difficulty` = 2 AND `dungeon_encounter_id` = 931));

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19650, `chaotic_link_stacks` = 0, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 546 AND `objective_creature_entry` = 17770
  AND ((`segment_id` = 773 AND `difficulty` = 0 AND `dungeon_encounter_id` = 320)
    OR (`segment_id` = 884 AND `difficulty` = 2 AND `dungeon_encounter_id` = 934));

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19651, `chaotic_link_stacks` = 0, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 547 AND `objective_creature_entry` = 17991
  AND ((`segment_id` = 770 AND `difficulty` = 0 AND `dungeon_encounter_id` = 302)
    OR (`segment_id` = 881 AND `difficulty` = 2 AND `dungeon_encounter_id` = 939));

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19652, `chaotic_link_stacks` = 2, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 552 AND `objective_creature_entry` = 20870
  AND ((`segment_id` = 947 AND `difficulty` = 0 AND `dungeon_encounter_id` = 494)
    OR (`segment_id` = 918 AND `difficulty` = 2 AND `dungeon_encounter_id` = 941));

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19653, `chaotic_link_stacks` = 2, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 553 AND `objective_creature_entry` = 17976
  AND ((`segment_id` = 795 AND `difficulty` = 0 AND `dungeon_encounter_id` = 502)
    OR (`segment_id` = 906 AND `difficulty` = 2 AND `dungeon_encounter_id` = 945));

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19654, `chaotic_link_stacks` = 0, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 554 AND `objective_creature_entry` = 19219
  AND ((`segment_id` = 804 AND `difficulty` = 0 AND `dungeon_encounter_id` = 513)
    OR (`segment_id` = 915 AND `difficulty` = 2 AND `dungeon_encounter_id` = 950));

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19655, `chaotic_link_stacks` = 0, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 555 AND `objective_creature_entry` = 18667
  AND ((`segment_id` = 792 AND `difficulty` = 0 AND `dungeon_encounter_id` = 209)
    OR (`segment_id` = 903 AND `difficulty` = 2 AND `dungeon_encounter_id` = 954));

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19656, `chaotic_link_stacks` = 2, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 556 AND `objective_creature_entry` = 18472
  AND ((`segment_id` = 786 AND `difficulty` = 0 AND `dungeon_encounter_id` = 206)
    OR (`segment_id` = 897 AND `difficulty` = 2 AND `dungeon_encounter_id` = 957));

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19657, `chaotic_link_stacks` = 2, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 557 AND `objective_creature_entry` = 18341
  AND ((`segment_id` = 942 AND `difficulty` = 0 AND `dungeon_encounter_id` = 203)
    OR (`segment_id` = 1091 AND `difficulty` = 2 AND `dungeon_encounter_id` = 960));

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19658, `chaotic_link_stacks` = 0, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 558 AND `objective_creature_entry` = 18371
  AND ((`segment_id` = 784 AND `difficulty` = 0 AND `dungeon_encounter_id` = 201)
    OR (`segment_id` = 895 AND `difficulty` = 2 AND `dungeon_encounter_id` = 964));

UPDATE `manastorm_segment`
SET `start_game_tele_id` = 19659, `chaotic_link_stacks` = 0, `flags` = (`flags` | 1), `enabled` = 1
WHERE `map_id` = 585 AND `objective_creature_entry` = 24744
  AND ((`segment_id` = 812 AND `difficulty` = 0 AND `dungeon_encounter_id` = 416)
    OR (`segment_id` = 923 AND `difficulty` = 2 AND `dungeon_encounter_id` = 970));

DELETE FROM `manastorm_segment_spawn`
WHERE `segment_id` IN (755, 866) AND `spawn_guid` IN (138188, 138191);

DELETE FROM `manastorm_segment_spawn`
WHERE `segment_id` IN (781, 892) AND `spawn_guid` IN (142124, 142125);

DELETE FROM `manastorm_segment_spawn`
WHERE `segment_id` IN (947, 918) AND `spawn_guid` IN (138926, 138930);

DELETE FROM `manastorm_segment_spawn`
WHERE `segment_id` IN (795, 906) AND `spawn_guid` IN (147008, 147013);

DELETE FROM `manastorm_segment_spawn`
WHERE `segment_id` IN (786, 897) AND `spawn_guid` IN (138671, 138672);

DELETE FROM `manastorm_segment_spawn`
WHERE `segment_id` IN (942, 1091) AND `spawn_guid` IN (83310, 83320);

INSERT INTO `manastorm_segment_spawn` (`segment_id`, `spawn_guid`, `flags`, `enabled`)
VALUES
(755, 138188, 3, 1),
(866, 138188, 3, 1),
(755, 138191, 3, 1),
(866, 138191, 3, 1),
(781, 142124, 3, 1),
(892, 142124, 3, 1),
(781, 142125, 3, 1),
(892, 142125, 3, 1),
(947, 138926, 3, 1),
(918, 138926, 3, 1),
(947, 138930, 3, 1),
(918, 138930, 3, 1),
(795, 147008, 3, 1),
(906, 147008, 3, 1),
(795, 147013, 3, 1),
(906, 147013, 3, 1),
(786, 138671, 3, 1),
(897, 138671, 3, 1),
(786, 138672, 3, 1),
(897, 138672, 3, 1),
(942, 83310, 3, 1),
(1091, 83310, 3, 1),
(942, 83320, 3, 1),
(1091, 83320, 3, 1);

COMMIT;
