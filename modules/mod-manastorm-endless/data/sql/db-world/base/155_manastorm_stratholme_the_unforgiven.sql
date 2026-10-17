-- Stratholme / The Unforgiven (native NPC 10516, map 329).
--
-- Recovered original Ascension Manastorm routes:
--   130 = Normal  (difficulty 0), dungeon encounter  472
--   354 = Endgame (difficulty 2), dungeon encounter 2472
-- Alternate original routes to retain but disable:
--   132 = duplicate Normal; 355 = duplicate Endgame
--
-- Exact player-authored arrival teleport (NOT the boss spawn):
--   2192, X 3627.24, Y -3336.06, Z 123.063,
--   orientation 0.0000109673, map 329,
--   'Manastorm_Stratholme_TheUnforgiven'
--
-- In the original dungeon The Unforgiven emerges with Vengeful
-- Phantoms when players pass a specific archway. The checked native
-- instance_stratholme.cpp has no handler to guarantee this boss on
-- a directly teleported disposable Manastorm stage.
--
-- ManastormMgr.cpp has a private-instance-only bootstrap for exactly
-- these two original segment IDs. It prefers a native DB spawn and
-- otherwise summons the boss in the historically reported archway
-- area with his phantom companions. It does not change normal
-- Stratholme, shared DB creature spawns, or its separate gate traps.
--
-- Rerunnable, guarded migration. Preserve Chaotic Link candidates,
-- stacks, weights, depths, rewards and unrelated flags.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2192, 3627.24, -3336.06, 123.063, 0.0000109673, 329,
     'Manastorm_Stratholme_TheUnforgiven');

-- Historical duplicates stay in the DB, but are not selectable.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 329
  AND `objective_creature_entry` = 10516
  AND ((`segment_id` = 132
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 472)
    OR (`segment_id` = 355
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2472));

-- Select one original recovered route per difficulty. OR the
-- StartingUnlocked flag (0x1) without clearing other existing bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2192,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 130
     AND `map_id` = 329
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 472
     AND `objective_creature_entry` = 10516
     AND `start_game_tele_id` IN (0, 2192))
 OR (`segment_id` = 354
     AND `map_id` = 329
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2472
     AND `objective_creature_entry` = 10516
     AND `start_game_tele_id` IN (0, 2192));

-- Read-only verification after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 329 AND objective_creature_entry = 10516
-- ORDER BY difficulty, segment_id;
