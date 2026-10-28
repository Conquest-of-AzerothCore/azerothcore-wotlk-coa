-- Deadmines / Cookie.
--
-- Enable exactly one Normal and one Endgame Manastorm segment with the
-- user-authored start position. Preserve unused recovered alternate routes.
--
-- Recovered Manastorm identities:
--   125 = Normal,  map 36, encounter 165,  objective 645
--   226 = Endgame, map 36, encounter 2165, objective 645
--
-- Unused native variants:
--   Normal: 128
--   Endgame: 229
--
-- User-authored starting teleport:
--   game_tele 2121, map 36
--   -68.8485, -903.338, 15.0094, orientation 1.57237
--
-- Preserve existing Chaotic Link candidates and stack counts, segment
-- weights, native encounter identities and other stage tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2121, -68.8485, -903.338, 15.0094, 1.57237, 36,
     'Manastorm_Deadmines_Cookie');

-- Preserve the native route variants but prevent duplicate Cookie stages.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 36
  AND `objective_creature_entry` = 645
  AND `segment_id` IN (128, 229);

-- Baseline dungeon content: StartingUnlocked (bit 0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2121,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 125
     AND `map_id` = 36
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 165
     AND `objective_creature_entry` = 645
     AND `start_game_tele_id` IN (0, 2121))
 OR (`segment_id` = 226
     AND `map_id` = 36
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2165
     AND `objective_creature_entry` = 645
     AND `start_game_tele_id` IN (0, 2121));

-- Verify:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 36 AND objective_creature_entry = 645
-- ORDER BY segment_id;
