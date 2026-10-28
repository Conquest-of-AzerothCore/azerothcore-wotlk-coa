-- Dire Maul East / Zevrim Thornhoof.
--
-- Recovered native Manastorm identities (map 429, objective 11490):
--   165 = Normal,  encounter 343
--   249 = Endgame, encounter 2343
--   Unselected historical routes: 166 (Normal), 250 (Endgame).
--
-- User-authored starting teleport (preserved exactly as supplied):
--   2135, map 429, X -1.70193, Y -480.244, Z -36.411,
--   orientation 1.57472
--
-- Preserve all manually authored Chaotic Link spawn candidates, stack
-- counts, weights, depth settings, rewards and other segment tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2135, -1.70193, -480.244, -36.411, 1.57472, 429,
     'Manastorm_DireMaul_ZeavrimThornhoof');

-- Retain historical alternative routes but exclude them from selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 429
  AND `objective_creature_entry` = 11490
  AND (
      (`segment_id` = 166
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 343)
   OR (`segment_id` = 250
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2343)
  );

-- Baseline dungeon availability: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2135,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 165
     AND `map_id` = 429
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 343
     AND `objective_creature_entry` = 11490
     AND `start_game_tele_id` IN (0, 2135))
 OR (`segment_id` = 249
     AND `map_id` = 429
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2343
     AND `objective_creature_entry` = 11490
     AND `start_game_tele_id` IN (0, 2135));

-- Verify selected routes and disabled historical alternatives:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 429 AND objective_creature_entry = 11490
-- ORDER BY segment_id;
