-- Scarlet Monastery / Herod (Armory).
--
-- Recovered native Manastorm identities (map 189, objective 3975):
--   110 = Normal,  encounter 448
--   315 = Endgame, encounter 2448
--   No alternative native Herod objective routes in the recovered catalogue.
--
-- User-authored starting teleport (name preserved exactly as supplied):
--   2133, map 189, X 1838.46, Y -428.516, Z 18.6782,
--   orientation 0.0581021
--
-- Herod's Door: GO entry 101854, spawn GUID 32250 at
--   X 1933.69, Y -431.654, Z 18.671.
-- ManastormScarletMonasteryCompat.cpp opens this door only in the exact
-- disposable private Herod stage. Ordinary Scarlet Monastery is unaffected.
--
-- Preserve all existing Chaotic Link spawns, stack counts, weights, depth,
-- reward tuning and manually authored stage settings.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2133, 1838.46, -428.516, 18.6782, 0.0581021, 189,
     'Manastorm_ScarletMonastery_Herodd');

-- Baseline dungeon eligibility: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2133,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 110
     AND `map_id` = 189
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 448
     AND `objective_creature_entry` = 3975
     AND `start_game_tele_id` IN (0, 2133))
 OR (`segment_id` = 315
     AND `map_id` = 189
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2448
     AND `objective_creature_entry` = 3975
     AND `start_game_tele_id` IN (0, 2133));

-- Verify:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 189 AND objective_creature_entry = 3975
-- ORDER BY segment_id;
