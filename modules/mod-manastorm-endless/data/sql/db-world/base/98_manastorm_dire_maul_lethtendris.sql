-- Dire Maul East / Lethtendris.
--
-- Recovered native Manastorm identities (map 429, objective 14327):
--   156 = Normal,  encounter 345
--   254 = Endgame, encounter 2345
--   Unselected historical routes: 160, 161 (Normal), 258 (Endgame).
--
-- User-authored starting teleport (name preserved exactly as supplied):
--   2137, map 429, X 87.1347, Y -450.334, Z -2.72374,
--   orientation 3.02693
--
-- Preserve manually authored Chaotic Link candidates, stack counts,
-- weights, depth settings, rewards and other segment tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2137, 87.1347, -450.334, -2.72374, 3.02693, 429,
     'Manastorm_DireMaul_Lethtendiris');

-- Keep the native alternative routes intact but out of selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 429
  AND `objective_creature_entry` = 14327
  AND (
      (`segment_id` IN (160, 161)
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 345)
   OR (`segment_id` = 258
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2345)
  );

-- Baseline dungeon availability: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2137,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 156
     AND `map_id` = 429
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 345
     AND `objective_creature_entry` = 14327
     AND `start_game_tele_id` IN (0, 2137))
 OR (`segment_id` = 254
     AND `map_id` = 429
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2345
     AND `objective_creature_entry` = 14327
     AND `start_game_tele_id` IN (0, 2137));

-- Verify selected routes and disabled historical alternatives:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 429 AND objective_creature_entry = 14327
-- ORDER BY segment_id;
