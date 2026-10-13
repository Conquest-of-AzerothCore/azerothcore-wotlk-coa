-- Manastorm: one enabled native route per boss and difficulty.
--
-- Based on the user's complete acore_world.manastorm_segment snapshot and
-- a read-only audit grouping enabled records by
-- (map_id, difficulty, dungeon_encounter_id).
--
-- Preserve the original, already-configured first route for each boss:
--   Bazil Thredd             map 34   Normal 58 (tele 2045), Endgame 374 (tele 2045)
--   Taragaman the Hungerer   map 389  Normal 1  (tele 2040), Endgame 288 (tele 2040)
--   Targorr the Dread        map 34   Normal 54 (tele 2042), Endgame 371 (tele 2042)
--
-- Disable only the sixteen exact alternate segment identities below.
-- DO NOT delete catalogue, spawns, manually configured Chaotic Links,
-- teleport definitions, weights, progression, reward data, or stage AI.
-- Each guarded UPDATE is rerunnable and never changes the retained pair.
-- This migration intentionally does NOT change encounter-repeat selection;
-- that is a separate generator policy decision.

-- Bazil Thredd: Normal (keep segment 58, teleport 2045).
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 34
  AND `difficulty` = 0
  AND `dungeon_encounter_id` = 539
  AND `objective_creature_entry` = 1716
  AND `segment_id` IN (59, 60, 61, 62);

-- Bazil Thredd: Endgame (keep segment 374, teleport 2045).
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 34
  AND `difficulty` = 2
  AND `dungeon_encounter_id` = 2539
  AND `objective_creature_entry` = 1716
  AND `segment_id` IN (375, 376, 377, 378);

-- Taragaman the Hungerer: Normal (keep segment 1, teleport 2040).
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 389
  AND `difficulty` = 0
  AND `dungeon_encounter_id` = 431
  AND `objective_creature_entry` = 11520
  AND `segment_id` IN (16, 17, 18);

-- Taragaman the Hungerer: Endgame (keep segment 288, teleport 2040).
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 389
  AND `difficulty` = 2
  AND `dungeon_encounter_id` = 2431
  AND `objective_creature_entry` = 11520
  AND `segment_id` IN (289, 290, 291);

-- Targorr the Dread: Normal (keep segment 54, teleport 2042).
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 34
  AND `difficulty` = 0
  AND `dungeon_encounter_id` = 536
  AND `objective_creature_entry` = 1696
  AND `segment_id` IN (55);

-- Targorr the Dread: Endgame (keep segment 371, teleport 2042).
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 34
  AND `difficulty` = 2
  AND `dungeon_encounter_id` = 2536
  AND `objective_creature_entry` = 1696
  AND `segment_id` IN (372);

-- Read-only verification: should return no rows for the entire enabled catalogue.
-- SELECT
--     map_id, difficulty, dungeon_encounter_id,
--     COUNT(*) AS active_routes,
--     GROUP_CONCAT(segment_id ORDER BY segment_id) AS segment_ids
-- FROM manastorm_segment
-- WHERE enabled = 1
-- GROUP BY map_id, difficulty, dungeon_encounter_id
-- HAVING COUNT(*) > 1
-- ORDER BY map_id, difficulty, dungeon_encounter_id;
--
-- Confirm the six retained stages and their original authored settings:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id, weight,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE segment_id IN (1, 54, 58, 288, 371, 374)
-- ORDER BY map_id, difficulty, segment_id;
