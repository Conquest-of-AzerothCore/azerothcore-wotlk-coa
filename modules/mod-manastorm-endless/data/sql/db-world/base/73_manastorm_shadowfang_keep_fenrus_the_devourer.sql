-- Shadowfang Keep / Fenrus the Devourer.
--
-- Restore one Normal and one Endgame Manastorm segment per boss.
-- Preserve the remaining native variants in the catalogue, disabled.
--
-- Native current catalogue identities:
--   39  = Normal,  map 33, encounter 469,  objective 4274
--   341 = Endgame, map 33, encounter 2469, objective 4274
--
-- Redundant Fenrus variants:
--   Normal: 40, 41, 43
--   Endgame: 343, 344, 345
--
-- User-authored start/bubble:
--   game_tele 2113, map 33
--   -173.326, 2173.47, 94.0559, orientation 5.99653
--
-- Keep all existing Chaotic Link entries, stack counts, weights, and
-- recovered native encounter/objective identities unchanged.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2113, -173.326, 2173.47, 94.0559, 5.99653, 33,
     'Manastorm_SFK_FenrustheDevourer');

-- Disable alternate routes; do not delete their archaeological identities.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 33
  AND `objective_creature_entry` = 4274
  AND `segment_id` IN (40, 41, 43, 343, 344, 345);

-- Baseline Vanilla dungeon encounter: StartingUnlocked (bit 0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2113,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 39
     AND `map_id` = 33
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 469
     AND `objective_creature_entry` = 4274
     AND `start_game_tele_id` IN (0, 2113))
 OR (`segment_id` = 341
     AND `map_id` = 33
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2469
     AND `objective_creature_entry` = 4274
     AND `start_game_tele_id` IN (0, 2113));

-- Verify:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 33 AND objective_creature_entry = 4274
-- ORDER BY segment_id;
