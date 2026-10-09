-- Razorfen Kraul / Agathelos the Raging.
--
-- Restore the recovered Normal and Endgame Manastorm objective stages.
-- The native Ward of Agathelos (gameobject entry 21099, DB spawn 35698)
-- blocks the passage in a fresh dungeon instance. A private-only scripted
-- ward opening for these two stages lives in ManastormRazorfenKraulCompat.cpp.
--
-- Recovered Manastorm identities:
--    88 = Normal,  map 47, encounter 883,  objective 4422
--   401 = Endgame, map 47, encounter 2883, objective 4422
--
-- User-authored teleport:
--   2127, map 47, X 2098.73, Y 1907.81, Z 70.2536,
--   orientation 2.56906.
--
-- Preserve existing Chaotic Link candidates, link stack requirements,
-- native encounter identities, weights and all other segment tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2127, 2098.73, 1907.81, 70.2536, 2.56906, 47,
     'Manastorm_RazorfenKraul_AgathelostheRaging');

-- Baseline dungeon availability: StartingUnlocked bit 0x1.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2127,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 88
     AND `map_id` = 47
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 883
     AND `objective_creature_entry` = 4422
     AND `start_game_tele_id` IN (0, 2127))
 OR (`segment_id` = 401
     AND `map_id` = 47
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2883
     AND `objective_creature_entry` = 4422
     AND `start_game_tele_id` IN (0, 2127));

-- Verify:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 47 AND objective_creature_entry = 4422
-- ORDER BY segment_id;
