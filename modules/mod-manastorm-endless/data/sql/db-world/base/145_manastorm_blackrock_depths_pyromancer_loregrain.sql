-- Blackrock Depths / Pyromancer Loregrain (native NPC 9024, map 230).
--
-- Exact original Ascension Manastorm routes:
--   420 = Normal  (difficulty 0), dungeon encounter  231
--   467 = Endgame (difficulty 2), dungeon encounter 2231
-- No alternate Loregrain routes exist in the recovered catalogue.
--
-- Exact player-authored arrival teleport:
--   2182, X 676.544, Y -280.736, Z -43.2048,
--   orientation 3.28374, map 230,
--   'Manastorm_BlackrockDepths_PyromancerLoregrain'
--
-- The current BRD instance script has no Loregrain-specific spawn,
-- unlock, or activation handler. Preserve the native DB creature
-- spawn and combat behavior; do not modify public BRD or boss AI.
--
-- Rerunnable and guarded by original segment identities. Preserve
-- all existing Chaotic Link candidates/stacks, weights, depths,
-- rewards, and unrelated flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2182, 676.544, -280.736, -43.2048, 3.28374, 230,
     'Manastorm_BlackrockDepths_PyromancerLoregrain');

-- Enable one recovered original segment per difficulty, preserving
-- existing flags by OR-ing StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2182,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 420
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 231
     AND `objective_creature_entry` = 9024
     AND `start_game_tele_id` IN (0, 2182))
 OR (`segment_id` = 467
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2231
     AND `objective_creature_entry` = 9024
     AND `start_game_tele_id` IN (0, 2182));

-- Read-only verification after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 9024
-- ORDER BY difficulty, segment_id;
