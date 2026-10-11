-- Dire Maul East / Hydrospawn.
--
-- Recovered native Manastorm identities (map 429, objective 13280):
--   162 = Normal,  encounter 344
--   251 = Endgame, encounter 2344
--   Unselected historical routes: 163, 164 (Normal), 252, 253 (Endgame).
--
-- User-authored starting teleport (preserved exactly as supplied):
--   2136, map 429, X -126.048, Y -446.007, Z -57.9176,
--   orientation 6.25177
--
-- Preserve manually authored Chaotic Link candidates, stack counts,
-- weights, depth settings, rewards and other segment tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2136, -126.048, -446.007, -57.9176, 6.25177, 429,
     'Manastorm_DireMaul_Hydrospawn');

-- Retain the original alternate routes but exclude them from selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 429
  AND `objective_creature_entry` = 13280
  AND (
      (`segment_id` IN (163, 164)
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 344)
   OR (`segment_id` IN (252, 253)
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2344)
  );

-- Baseline dungeon availability: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2136,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 162
     AND `map_id` = 429
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 344
     AND `objective_creature_entry` = 13280
     AND `start_game_tele_id` IN (0, 2136))
 OR (`segment_id` = 251
     AND `map_id` = 429
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2344
     AND `objective_creature_entry` = 13280
     AND `start_game_tele_id` IN (0, 2136));

-- Verify selected routes and disabled historical alternatives:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 429 AND objective_creature_entry = 13280
-- ORDER BY segment_id;
