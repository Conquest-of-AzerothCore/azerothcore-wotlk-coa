-- Razorfen Kraul / Overlord Ramtusk.
--
-- Restore one recovered Normal and one Endgame Manastorm segment using
-- the user-authored start position; preserve native encounter identities.
--
-- Recovered Manastorm identities:
--    87 = Normal,  map 47, encounter 441,  objective 4420
--   305 = Endgame, map 47, encounter 2441, objective 4420
--
-- User-authored starting position:
--   game_tele 2126, map 47
--   X 2182.05, Y 1586.51, Z 78.3053, orientation 1.11918
--
-- No redundant Ramtusk route variants exist in the recovered Razorfen
-- Kraul catalogue. Preserve existing Chaotic Link candidates, stack
-- requirements, weights and all other segment tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2126, 2182.05, 1586.51, 78.3053, 1.11918, 47,
     'Manastorm_RazorfenKraul_OverlordRamtusk');

-- Baseline dungeon availability: StartingUnlocked bit 0x1.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2126,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 87
     AND `map_id` = 47
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 441
     AND `objective_creature_entry` = 4420
     AND `start_game_tele_id` IN (0, 2126))
 OR (`segment_id` = 305
     AND `map_id` = 47
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2441
     AND `objective_creature_entry` = 4420
     AND `start_game_tele_id` IN (0, 2126));

-- Verify:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 47 AND objective_creature_entry = 4420
-- ORDER BY segment_id;
