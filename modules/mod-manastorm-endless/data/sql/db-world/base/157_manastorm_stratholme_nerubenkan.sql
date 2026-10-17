-- Stratholme / Nerub'enkan (native NPC 10437, map 329).
--
-- Recovered original Ascension Manastorm routes:
--   142 = Normal  (difficulty 0), dungeon encounter  480
--   360 = Endgame (difficulty 2), dungeon encounter 2480
-- Duplicate historical routes to retain but disable:
--   146 = alternate Normal; 361 = alternate Endgame
--
-- Exact player-authored arrival teleport (not the native boss spawn):
--   2194, X 3791.61, Y -3605.48, Z 145.04,
--   orientation 5.47894, map 329,
--   'Manastorm_Stratholme_Nerub''enkan'
--
-- The native Stratholme instance script tracks the second ziggurat
-- through TYPE_ZIGGURAT2 and its door GO 175379. This progression
-- ultimately contributes to opening the downstream gauntlet; it is
-- not a prerequisite for Nerub'enkan himself to be attackable.
-- Do not force this ziggurat to DONE or change native map state.
-- Preserve native creature spawn, combat, and encounter behavior.
-- Verify reachability and boss objective registration in-game.
--
-- Rerunnable migration scoped to exact original segment identities.
-- Preserve Chaotic Link candidates/stacks, weights, depths, rewards,
-- and unrelated flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2194, 3791.61, -3605.48, 145.04, 5.47894, 329,
     'Manastorm_Stratholme_Nerub''enkan');

-- Keep alternate recovered routes recorded, but not selectable.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 329
  AND `objective_creature_entry` = 10437
  AND ((`segment_id` = 146
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 480)
    OR (`segment_id` = 361
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2480));

-- Enable one original route per difficulty, adding StartingUnlocked
-- (0x1) without clearing other existing flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2194,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 142
     AND `map_id` = 329
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 480
     AND `objective_creature_entry` = 10437
     AND `start_game_tele_id` IN (0, 2194))
 OR (`segment_id` = 360
     AND `map_id` = 329
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2480
     AND `objective_creature_entry` = 10437
     AND `start_game_tele_id` IN (0, 2194));

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 329 AND objective_creature_entry = 10437
-- ORDER BY difficulty, segment_id;
