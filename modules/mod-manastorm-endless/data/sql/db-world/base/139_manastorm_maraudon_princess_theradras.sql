-- Maraudon / Princess Theradras (native NPC 12201, map 349).
--
-- Original Ascension Manastorm encounter identity:
--   438 = Normal  (difficulty 0), dungeon encounter  429
--   448 = Endgame (difficulty 2), dungeon encounter 2429
--
-- Recovered duplicate routes for the identical boss/encounter:
--   439 = alternate Normal route: retain, disabled
--   449 = alternate Endgame route: retain, disabled
-- No invented segments or extra routes; one enabled per difficulty.
--
-- Exact player-authored arrival game_tele (keep name as entered):
--   id 2176, X 108.61, Y -268.256, Z -108.677,
--   orientation 3.01591, map 349,
--   'Manastorm_Maraudon_Princess'
--
-- Native Maraudon instance script contains no Princess Theradras
-- activation/door prerequisite. Preserve original native DB boss
-- spawn, combat AI, and optional post-boss quest behavior.
-- No public instance-script or Manastorm C++ changes are needed.
--
-- Idempotent. Preserve manually configured Chaotic Link candidates
-- and stack counts, weights, depths, rewards, other flag bits,
-- and unrelated dungeon segments.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2176, 108.61, -268.256, -108.677, 3.01591, 349,
     'Manastorm_Maraudon_Princess');

-- Keep duplicate original routes as disabled historical records.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 349
  AND `objective_creature_entry` = 12201
  AND ((`segment_id` = 439
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 429)
    OR (`segment_id` = 449
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2429));

-- Use the same teleport for the original Normal and Endgame routes.
-- Preserve all existing flags via OR StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2176,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 438
     AND `map_id` = 349
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 429
     AND `objective_creature_entry` = 12201
     AND `start_game_tele_id` IN (0, 2176))
 OR (`segment_id` = 448
     AND `map_id` = 349
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2429
     AND `objective_creature_entry` = 12201
     AND `start_game_tele_id` IN (0, 2176));

-- Read-only post-import verification:
-- SELECT segment_id,map_id,difficulty,dungeon_encounter_id,
--        objective_creature_entry,start_game_tele_id,
--        chaotic_link_stacks,weight,flags,enabled
-- FROM manastorm_segment
-- WHERE map_id=349 AND objective_creature_entry=12201
-- ORDER BY difficulty,segment_id;
