-- Stratholme / Malor the Zealous (native NPC 11032, map 329).
--
-- Recovered original Ascension Manastorm routes:
--   176 = Normal  (difficulty 0), dungeon encounter  476
--   546 = Endgame (difficulty 2), dungeon encounter 2476
-- No duplicate historical Malor routes were recovered.
--
-- Exact player-authored arrival teleport (not a boss-spawn position):
--   2197, X 3633.52, Y -3112.01, Z 134.117,
--   orientation 0.596905, map 329,
--   'Manastorm_Stratholme_MalorTheZealous'
--
-- The current native instance_stratholme.cpp and stratholme.h
-- do not contain a Malor-specific summoning, activation, or
-- prerequisite-event handler. The Scarlet-side gate/postbox
-- mechanics are separate dungeon progression; do not force them
-- or alter normal Stratholme for this isolated Manastorm stage.
-- Reuse Malor's native world DB spawn and combat behavior.
-- Verify spawn, access and objective completion in-game.
--
-- Rerunnable and restricted to exact recovered segment identities.
-- Preserve existing Chaotic Link candidates and stacks, weights,
-- depths, rewards, and unrelated flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2197, 3633.52, -3112.01, 134.117, 0.596905, 329,
     'Manastorm_Stratholme_MalorTheZealous');

-- Enable exactly one original route for each difficulty, adding
-- StartingUnlocked (0x1) without clearing any pre-existing flags.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2197,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 176
     AND `map_id` = 329
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 476
     AND `objective_creature_entry` = 11032
     AND `start_game_tele_id` IN (0, 2197))
 OR (`segment_id` = 546
     AND `map_id` = 329
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2476
     AND `objective_creature_entry` = 11032
     AND `start_game_tele_id` IN (0, 2197));

-- Read-only verification after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 329 AND objective_creature_entry = 11032
-- ORDER BY difficulty, segment_id;
