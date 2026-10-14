-- Blackrock Depths / Fineous Darkvire (native NPC 9056, map 230).
--
-- Recovered original Ascension Manastorm routes:
--   700 = Normal  (difficulty 0), dungeon encounter  234
--   699 = Endgame (difficulty 2), dungeon encounter 2234
-- No duplicate historical Fineous routes were recovered.
--
-- Exact player-authored arrival teleport (not the boss spawn):
--   2191, X 896.61, Y -351.215, Z -49.9375,
--   orientation 4.79095, map 230,
--   'Manastorm_BlackRockDepths_FineousDarkvire'
--
-- Current native BRD instance and general dungeon scripts do not
-- contain Fineous-specific activation, scripted summons, or an
-- encounter unlock requirement. Reuse the original DB creature
-- and patrol instead of creating a duplicate or altering instance
-- progression. Validate access/patrol in a private in-game stage.
--
-- Rerunnable and restricted to exact original segment identities.
-- Preserve Chaotic Link candidates/stacks, weights, depths,
-- rewards, and all unrelated flags.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2191, 896.61, -351.215, -49.9375, 4.79095, 230,
     'Manastorm_BlackRockDepths_FineousDarkvire');

-- Enable one original route per difficulty; preserve all existing
-- flag bits while adding StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2191,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 700
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 234
     AND `objective_creature_entry` = 9056
     AND `start_game_tele_id` IN (0, 2191))
 OR (`segment_id` = 699
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2234
     AND `objective_creature_entry` = 9056
     AND `start_game_tele_id` IN (0, 2191));

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 9056
-- ORDER BY difficulty, segment_id;
