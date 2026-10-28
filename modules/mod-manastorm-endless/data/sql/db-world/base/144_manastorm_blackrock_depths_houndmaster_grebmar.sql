-- Blackrock Depths / Houndmaster Grebmar (native NPC 9319, map 230).
--
-- Recovered original Ascension Manastorm routes:
--   419 = Normal  (difficulty 0), dungeon encounter  229
--   468 = Endgame (difficulty 2), dungeon encounter 2229
-- No duplicate original Grebmar routes were recovered.
--
-- Exact player-authored arrival teleport:
--   2181, X 621.465, Y -234.968, Z -82.9242,
--   orientation 2.09702, map 230,
--   'Manastorm_BlackrockDepths_HoundmasterGrebmar'
--
-- Current BRD instance scripts have no Grebmar-specific activation,
-- summoning or progression requirement. Retain his native DB spawn
-- and creature combat behavior; no private-instance C++ changes.
--
-- Rerunnable and guarded by original segment identity. Preserve
-- Chaotic Link candidates/stacks, weights, depths and rewards.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2181, 621.465, -234.968, -82.9242, 2.09702, 230,
     'Manastorm_BlackrockDepths_HoundmasterGrebmar');

-- Enable the original Normal and Endgame routes. Preserve all other
-- flag bits by OR-ing StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2181,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 419
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 229
     AND `objective_creature_entry` = 9319
     AND `start_game_tele_id` IN (0, 2181))
 OR (`segment_id` = 468
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2229
     AND `objective_creature_entry` = 9319
     AND `start_game_tele_id` IN (0, 2181));

-- Read-only verification after import:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 9319
-- ORDER BY difficulty, segment_id;
