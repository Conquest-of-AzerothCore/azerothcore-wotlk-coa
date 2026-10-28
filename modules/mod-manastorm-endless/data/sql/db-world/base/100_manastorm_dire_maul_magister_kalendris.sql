-- Dire Maul West / Magister Kalendris.
--
-- Recovered native Manastorm identities (map 429, objective 11487):
--   177 = Normal,  encounter 348
--   208 = Endgame, encounter 2348
--   Unselected historical routes: 178, 179 (Normal), 209, 210 (Endgame).
--
-- User-authored starting teleport (preserved exactly as supplied):
--   2139, map 429, X -110.862, Y 576.451, Z -4.39553,
--   orientation 5.70832
--
-- Preserve manually authored Chaotic Link candidates, stack counts,
-- weights, depth settings, rewards and other segment tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2139, -110.862, 576.451, -4.39553, 5.70832, 429,
     'Manastorm_DireMaul_MagisterKalendris');

-- Keep original historical alternatives intact but out of selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 429
  AND `objective_creature_entry` = 11487
  AND (
      (`segment_id` IN (178, 179)
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 348)
   OR (`segment_id` IN (209, 210)
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2348)
  );

-- Baseline dungeon availability: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2139,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 177
     AND `map_id` = 429
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 348
     AND `objective_creature_entry` = 11487
     AND `start_game_tele_id` IN (0, 2139))
 OR (`segment_id` = 208
     AND `map_id` = 429
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2348
     AND `objective_creature_entry` = 11487
     AND `start_game_tele_id` IN (0, 2139));

-- Verify both selected routes and the four disabled alternatives:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 429 AND objective_creature_entry = 11487
-- ORDER BY segment_id;
