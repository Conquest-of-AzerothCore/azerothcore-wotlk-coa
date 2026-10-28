-- Blackrock Depths / High Interrogator Gerstahn (native NPC 9018, map 230).
--
-- Original recovered Ascension Manastorm routes:
--   415 = Normal  (difficulty 0), dungeon encounter  227
--   471 = Endgame (difficulty 2), dungeon encounter 2227
-- Duplicate original routes to retain but disable:
--   416 = alternate Normal; 472 = alternate Endgame
--
-- Exact player-authored arrival teleport:
--   2179, X 446.493, Y -111.723, Z -65.3763,
--   orientation 3.39056, map 230,
--   'Manastorm_BlackRockdepths_HighInterrogatorGerstahn'
--
-- Native boss_high_interrogator_gerstahn.cpp contains ordinary combat
-- behavior, with no scripted wake-up or summoning prerequisite. The
-- instance_blackrock_depths.cpp script has no Gerstahn-specific
-- activation gate. Leave native creature spawn and combat AI intact.
--
-- Rerunnable, guarded migration. Preserve existing Chaotic Link
-- candidates/stacks, weights, depths, rewards, and unrelated flags.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2179, 446.493, -111.723, -65.3763, 3.39056, 230,
     'Manastorm_BlackRockdepths_HighInterrogatorGerstahn');

-- Retain historical duplicate records without allowing selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 230
  AND `objective_creature_entry` = 9018
  AND ((`segment_id` = 416
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 227)
    OR (`segment_id` = 472
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2227));

-- One original segment for each difficulty. StartingUnlocked is bit 0x1.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2179,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 415
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 227
     AND `objective_creature_entry` = 9018
     AND `start_game_tele_id` IN (0, 2179))
 OR (`segment_id` = 471
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2227
     AND `objective_creature_entry` = 9018
     AND `start_game_tele_id` IN (0, 2179));

-- Read-only verification after import:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 9018
-- ORDER BY difficulty, segment_id;
