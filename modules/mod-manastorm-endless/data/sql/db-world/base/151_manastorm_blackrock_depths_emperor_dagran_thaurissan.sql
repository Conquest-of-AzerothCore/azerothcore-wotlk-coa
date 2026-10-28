-- Blackrock Depths / Emperor Dagran Thaurissan (native NPC 9019, map 230).
--
-- Exact original recovered Ascension Manastorm routes:
--   431 = Normal  (difficulty 0), dungeon encounter  245
--   456 = Endgame (difficulty 2), dungeon encounter 2245
-- No alternate recovered Emperor route exists for either difficulty.
--
-- Exact player-authored arrival teleport (not a boss-spawn position):
--   2188, X 1380.95, Y -715.282, Z -92.0686,
--   orientation 4.70141, map 230,
--   'Manastorm_BlackrockDepths_EmperorDagranThaurissan'
--
-- Native boss_emperor_dagran_thaurissan.cpp handles Hand of
-- Thaurissan, Avatar of Flame, calls for help, senator commentary,
-- and the Princess Moira reaction on death. Native BRD instance
-- logic selects Moira/Priestess based on party quest state, while
-- Magmus normally opens the throne-room door (170575).
--
-- This migration does not force Magmus completion or alter the
-- native instance state. Verify that the authored arrival can reach
-- the Emperor behind any throne-room gate in the private stage.
-- Preserve the native NPC spawn and companion behavior.
--
-- Rerunnable, guarded migration. Preserve existing Chaotic Link
-- candidates/stacks, stage weights and depths, rewards and flags
-- beyond the added StartingUnlocked bit (0x1).

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2188, 1380.95, -715.282, -92.0686, 4.70141, 230,
     'Manastorm_BlackrockDepths_EmperorDagranThaurissan');

-- Exactly one original route per difficulty. Existing flag bits
-- survive because StartingUnlocked is OR-ed instead of replacing.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2188,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 431
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 245
     AND `objective_creature_entry` = 9019
     AND `start_game_tele_id` IN (0, 2188))
 OR (`segment_id` = 456
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2245
     AND `objective_creature_entry` = 9019
     AND `start_game_tele_id` IN (0, 2188));

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 9019
-- ORDER BY difficulty, segment_id;
