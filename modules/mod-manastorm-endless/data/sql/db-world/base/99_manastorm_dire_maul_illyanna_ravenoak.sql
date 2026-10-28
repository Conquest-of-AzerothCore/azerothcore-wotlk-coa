-- Dire Maul West / Illyanna Ravenoak.
--
-- Recovered native Manastorm identities (map 429, objective 11488):
--   181 = Normal,  encounter 347
--   259 = Endgame, encounter 2347
--   No historical alternative objective routes in the recovered catalogue.
--
-- User-authored starting teleport (preserved exactly as supplied):
--   2138, map 429, X 10.6104, Y 392.278, Z 25.0561,
--   orientation 2.49316
--
-- Preserve manually authored Chaotic Link candidates, stack counts,
-- weights, depth settings, rewards and all other stage tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2138, 10.6104, 392.278, 25.0561, 2.49316, 429,
     'Manastorm_DireMaul_IllyannaRavenoak');

-- Baseline dungeon availability: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2138,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 181
     AND `map_id` = 429
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 347
     AND `objective_creature_entry` = 11488
     AND `start_game_tele_id` IN (0, 2138))
 OR (`segment_id` = 259
     AND `map_id` = 429
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2347
     AND `objective_creature_entry` = 11488
     AND `start_game_tele_id` IN (0, 2138));

-- Verify both selected stages:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 429 AND objective_creature_entry = 11488
-- ORDER BY segment_id;
