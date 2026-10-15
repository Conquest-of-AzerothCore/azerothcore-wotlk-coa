-- Stratholme / Cannon Master Willey (native NPC 10997, map 329).
--
-- Recovered original Ascension Manastorm routes:
--   180 = Normal  (difficulty 0), dungeon encounter  475
--   356 = Endgame (difficulty 2), dungeon encounter 2475
-- No historical duplicate Cannon Master Willey routes recovered.
--
-- Exact player-authored arrival teleport (not a boss-spawn position):
--   2198, X 3565.64, Y -3047.96, Z 135.667,
--   orientation 2.2164, map 329,
--   'Manastorm_Stratholme_CannonMasterWilley'
--
-- The current native Stratholme instance script has no Willey-specific
-- summoning, activation or prerequisite-event handler. Keep the
-- original DB spawn and native cannon-room/combat behavior; do not
-- artificially fire cannons or modify dungeon instance progression.
-- Verify the authored arrival, boss registration and the native
-- encounter in a disposable Manastorm stage in-game.
--
-- Rerunnable, guarded migration. Preserve Chaotic Link candidates,
-- stacks, weights, depths, rewards and existing unrelated flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2198, 3565.64, -3047.96, 135.667, 2.2164, 329,
     'Manastorm_Stratholme_CannonMasterWilley');

-- Enable exactly one recovered route per difficulty. Preserve
-- other flag bits by OR-ing StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2198,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 180
     AND `map_id` = 329
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 475
     AND `objective_creature_entry` = 10997
     AND `start_game_tele_id` IN (0, 2198))
 OR (`segment_id` = 356
     AND `map_id` = 329
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2475
     AND `objective_creature_entry` = 10997
     AND `start_game_tele_id` IN (0, 2198));

-- Read-only verification after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 329 AND objective_creature_entry = 10997
-- ORDER BY difficulty, segment_id;
