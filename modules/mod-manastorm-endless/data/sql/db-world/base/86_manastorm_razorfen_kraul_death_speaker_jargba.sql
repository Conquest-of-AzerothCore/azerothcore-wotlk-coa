-- Razorfen Kraul / Death Speaker Jargba.
--
-- Restore exactly one Normal and one Endgame Manastorm stage, using the
-- user-authored start while keeping unused native variants in the catalogue.
--
-- Recovered Manastorm identities:
--    85 = Normal,  map 47, encounter 440,  objective 4428
--   303 = Endgame, map 47, encounter 2440, objective 4428
--
-- Unused native route variants:
--    86 (Normal) and 304 (Endgame).
--
-- User-authored start:
--   game_tele 2125, map 47
--   X 2197.98, Y 1535.23, Z 72.8089, orientation 4.48933
--
-- Preserve existing Chaotic Link candidates, stack requirements, segment
-- weights, native encounter identity and all other manually authored tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2125, 2197.98, 1535.23, 72.8089, 4.48933, 47,
     'Manastorm_RazorfenKraul_DeathSpeakerJargba');

-- Retain but disable the duplicate native routes.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 47
  AND `objective_creature_entry` = 4428
  AND `segment_id` IN (86, 304);

-- Baseline dungeon availability: StartingUnlocked bit 0x1.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2125,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 85
     AND `map_id` = 47
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 440
     AND `objective_creature_entry` = 4428
     AND `start_game_tele_id` IN (0, 2125))
 OR (`segment_id` = 303
     AND `map_id` = 47
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2440
     AND `objective_creature_entry` = 4428
     AND `start_game_tele_id` IN (0, 2125));

-- Verify selected and disabled routes:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 47 AND objective_creature_entry = 4428
-- ORDER BY segment_id;
