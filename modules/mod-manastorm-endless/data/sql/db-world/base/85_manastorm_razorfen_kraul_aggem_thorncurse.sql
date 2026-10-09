-- Razorfen Kraul / Aggem Thorncurse.
--
-- Restore one Normal and one Endgame Manastorm segment using the
-- user-authored teleport. Preserve all recovered native identities.
--
-- Recovered Manastorm catalogue:
--    84 = Normal,  map 47, encounter 439,  objective 4424
--   302 = Endgame, map 47, encounter 2439, objective 4424
--
-- User-authored starting position:
--   game_tele 2124, map 47
--   X 2171.5, Y 1542.18, Z 71.3176, orientation 3.88696
--
-- No extra native variants for Aggem appear in the recovered 19-row
-- Razorfen Kraul catalogue. Existing route/Chaotic Link candidates,
-- link stack counts, weights and all other segment tuning are retained.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2124, 2171.5, 1542.18, 71.3176, 3.88696, 47,
     'Manastorm_RazorfenKraul_AggemThorncurse');

-- Baseline dungeon availability: StartingUnlocked bit 0x1.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2124,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 84
     AND `map_id` = 47
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 439
     AND `objective_creature_entry` = 4424
     AND `start_game_tele_id` IN (0, 2124))
 OR (`segment_id` = 302
     AND `map_id` = 47
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2439
     AND `objective_creature_entry` = 4424
     AND `start_game_tele_id` IN (0, 2124));

-- Verify:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 47 AND objective_creature_entry = 4424
-- ORDER BY segment_id;
