-- Stratholme / Magistrate Barthilas (native NPC 10435, map 329).
--
-- Recovered original Ascension Manastorm routes:
--   138 = Normal  (difficulty 0), dungeon encounter  482
--   364 = Endgame (difficulty 2), dungeon encounter 2482
-- Duplicate historical routes to retain but disable:
--   141 = alternate Normal; 365 = alternate Endgame
--
-- Exact player-authored arrival teleport (not the native boss spawn):
--   2193, X 3655.52, Y -3552.67, Z 137.871,
--   orientation 5.0187, map 329,
--   'Manastorm_Stratholme_MagistrateBarthilas'
--
-- The native Stratholme instance tracks Barthilas's DB creature GUID.
-- TYPE_BARTHILAS_RUN (6) with DONE relocates a living Barthilas to
-- (4068.74, -3535.97, 122.825). That is a dungeon progression event,
-- not a boss spawning/unlock prerequisite. Do not force that event
-- in the standalone private Manastorm encounter. Preserve his native
-- creature movement and combat behavior, and verify reachability from
-- the authored arrival teleport during in-game tests.
--
-- Rerunnable, guarded migration. Preserve existing Chaotic Link
-- candidates and stacks, weights, depths, rewards, and flag bits
-- other than the additive StartingUnlocked (0x1) bit.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2193, 3655.52, -3552.67, 137.871, 5.0187, 329,
     'Manastorm_Stratholme_MagistrateBarthilas');

-- Keep the historical duplicate routes for reference, but disable
-- them so only one original segment is selectable per difficulty.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 329
  AND `objective_creature_entry` = 10435
  AND ((`segment_id` = 141
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 482)
    OR (`segment_id` = 365
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2482));

-- Enable the recovered originals without affecting other fields.
-- OR StartingUnlocked (0x1) to preserve all pre-existing flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2193,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 138
     AND `map_id` = 329
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 482
     AND `objective_creature_entry` = 10435
     AND `start_game_tele_id` IN (0, 2193))
 OR (`segment_id` = 364
     AND `map_id` = 329
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2482
     AND `objective_creature_entry` = 10435
     AND `start_game_tele_id` IN (0, 2193));

-- Read-only verification after import:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 329 AND objective_creature_entry = 10435
-- ORDER BY difficulty, segment_id;
