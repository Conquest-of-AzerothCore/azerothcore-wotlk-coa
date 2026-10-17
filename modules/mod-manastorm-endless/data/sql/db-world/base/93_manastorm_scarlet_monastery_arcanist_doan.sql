-- Scarlet Monastery / Arcanist Doan (Library).
--
-- Recovered native Manastorm identities (map 189, objective 6487):
--   108 = Normal,  encounter 447
--   313 = Endgame, encounter 2447
--   Unselected historical routes: 109 (Normal), 314 (Endgame)
--
-- User-authored starting teleport:
--   2132, map 189, X 264.921, Y -344.028, Z 20.0763,
--   orientation 4.71633
--
-- Preserve existing manually authored Chaotic Link candidate spawns, required
-- stacks, weights, depth settings, reward tuning and other segment data.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2132, 264.921, -344.028, 20.0763, 4.71633, 189,
     'Manastorm_ScarletMonastery_ArcanistDoan');

-- Keep alternate native routes intact but exclude them from selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 189
  AND `objective_creature_entry` = 6487
  AND (
      (`segment_id` = 109
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 447)
   OR (`segment_id` = 314
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2447)
  );

-- Baseline dungeon availability: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2132,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 108
     AND `map_id` = 189
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 447
     AND `objective_creature_entry` = 6487
     AND `start_game_tele_id` IN (0, 2132))
 OR (`segment_id` = 313
     AND `map_id` = 189
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2447
     AND `objective_creature_entry` = 6487
     AND `start_game_tele_id` IN (0, 2132));

-- Verify selected routes and disabled historical alternatives:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 189 AND objective_creature_entry = 6487
-- ORDER BY segment_id;
