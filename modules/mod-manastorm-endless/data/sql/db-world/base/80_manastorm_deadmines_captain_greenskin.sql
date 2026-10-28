-- Deadmines / Captain Greenskin.
--
-- Restore exactly one Normal and one Endgame Manastorm segment using
-- the user-authored start. Preserve the other native route variant.
--
-- Recovered Manastorm identities:
--   126 = Normal,  map 36, encounter 166,  objective 647
--   228 = Endgame, map 36, encounter 2166, objective 647
--
-- Unused native variant:
--   Normal: 127
--
-- User-authored start position:
--   game_tele 2120, map 36
--   -100.544, -791.458, 17.0539, orientation 3.18791
--
-- Preserve existing Chaotic Link candidates, stack requirements, weights,
-- native encounter identities, and all other segment tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2120, -100.544, -791.458, 17.0539, 3.18791, 36,
     'Manastorm_Deadmines_CaptainGreenskin');

-- Do not delete the redundant recovered Normal route.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 36
  AND `objective_creature_entry` = 647
  AND `segment_id` = 127;

-- Baseline dungeon content: StartingUnlocked bit (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2120,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 126
     AND `map_id` = 36
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 166
     AND `objective_creature_entry` = 647
     AND `start_game_tele_id` IN (0, 2120))
 OR (`segment_id` = 228
     AND `map_id` = 36
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2166
     AND `objective_creature_entry` = 647
     AND `start_game_tele_id` IN (0, 2120));

-- Verify:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 36 AND objective_creature_entry = 647
-- ORDER BY segment_id;
