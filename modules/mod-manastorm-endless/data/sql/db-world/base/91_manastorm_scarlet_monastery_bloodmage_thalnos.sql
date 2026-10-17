-- Scarlet Monastery / Bloodmage Thalnos (Graveyard).
--
-- Recovered native Manastorm identities (map 189, objective 4543):
--   103 = Normal,  encounter 445
--   308 = Endgame, encounter 2445
--   Unselected historical routes: 104, 105, 106 (Normal), 309 (Endgame)
--
-- User-authored starting teleport:
--   2130, map 189, X 1797.47, Y 1417.79, Z 14.1409,
--   orientation 0.0313928
--
-- Preserve existing Chaotic Link spawn candidates, required stacks, weights,
-- depths, rewards and all other manual segment tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2130, 1797.47, 1417.79, 14.1409, 0.0313928, 189,
     'Manastorm_ScarletMonastery_BloodmageThalnos');

-- Keep original alternate routes in the catalogue but out of selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 189
  AND `objective_creature_entry` = 4543
  AND (
      (`segment_id` IN (104, 105, 106)
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 445)
   OR (`segment_id` = 309
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2445)
  );

-- Baseline dungeon eligibility: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2130,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 103
     AND `map_id` = 189
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 445
     AND `objective_creature_entry` = 4543
     AND `start_game_tele_id` IN (0, 2130))
 OR (`segment_id` = 308
     AND `map_id` = 189
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2445
     AND `objective_creature_entry` = 4543
     AND `start_game_tele_id` IN (0, 2130));

-- Verify both selected stages and the four disabled alternatives:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 189 AND objective_creature_entry = 4543
-- ORDER BY segment_id;
