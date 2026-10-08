-- Shadowfang Keep / Archmage Arugal.
--
-- Restore exactly one Normal and one Endgame Manastorm segment for Arugal.
-- Keep alternate native route variants in the catalogue but disabled.
--
-- Recovered identities from the current Manastorm segment dump:
--   49  = Normal,  map 33, encounter 471,  objective 4275
--   350 = Endgame, map 33, encounter 2471, objective 4275
--
-- Unused native variants:
--   Normal: 52, 53
--   Endgame: 351
--
-- User-authored safety-bubble start:
--   game_tele 2115, map 33
--   -109.053, 2159.22, 155.678, orientation 4.77057
--
-- Preserve native encounter identity, existing Chaotic Link selections,
-- stack requirements, and per-segment weights/tuning.
-- If Arugal is locked behind an instance door, assess the run-time test
-- separately; do not alter normal Vanilla Shadowfang Keep behavior here.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2115, -109.053, 2159.22, 155.678, 4.77057, 33,
     'Manastorm_SFK_ArchmageArugal');

-- Disable redundant route variants without deleting recovered DBC identities.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 33
  AND `objective_creature_entry` = 4275
  AND `segment_id` IN (52, 53, 351);

-- Baseline dungeon content: enable StartingUnlocked bit (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2115,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 49
     AND `map_id` = 33
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 471
     AND `objective_creature_entry` = 4275
     AND `start_game_tele_id` IN (0, 2115))
 OR (`segment_id` = 350
     AND `map_id` = 33
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2471
     AND `objective_creature_entry` = 4275
     AND `start_game_tele_id` IN (0, 2115));

-- Verify:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 33 AND objective_creature_entry = 4275
-- ORDER BY segment_id;
