-- Blackrock Depths / Lord Roccor (native NPC 9025, map 230).
--
-- Original recovered Ascension Manastorm routes:
--   667 = Normal  (difficulty 0), dungeon encounter  228
--   666 = Endgame (difficulty 2), dungeon encounter 2228
-- No duplicate historical Roccor routes were recovered.
--
-- Exact player-authored arrival teleport (not a boss-spawn position):
--   2189, X 538.788, Y -198.644, Z -56.1377,
--   orientation 4.21364, map 230,
--   'Manastorm_BlackRockDepths_LordRoccor'
--
-- Native BRD instance and dungeon scripts contain no Lord Roccor
-- activation, summoning, or prerequisite-event handler. He patrols
-- the Halls of the Law in the native dungeon; do not create a copy
-- or overwrite his native DB spawn and movement.
--
-- Rerunnable and guarded by original stage identity. Preserve
-- Chaotic Link candidates and stacks, weights, depths, rewards,
-- and all pre-existing unrelated flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2189, 538.788, -198.644, -56.1377, 4.21364, 230,
     'Manastorm_BlackRockDepths_LordRoccor');

-- Enable exactly one recovered original route per difficulty.
-- OR StartingUnlocked (0x1) while retaining any other flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2189,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 667
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 228
     AND `objective_creature_entry` = 9025
     AND `start_game_tele_id` IN (0, 2189))
 OR (`segment_id` = 666
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2228
     AND `objective_creature_entry` = 9025
     AND `start_game_tele_id` IN (0, 2189));

-- Read-only verification after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 9025
-- ORDER BY difficulty, segment_id;
