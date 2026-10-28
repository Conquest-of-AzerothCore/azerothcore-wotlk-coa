-- Zul'Farrak / Antu'sul.
--
-- Recovered native Manastorm identities (map 209, objective 8127):
--   193 = Normal,  encounter 595
--   396 = Endgame, encounter 2595
--   Unselected original route variants:
--     194, 195, 196 (Normal); 397, 398, 399 (Endgame).
--
-- Start teleport authored in-game by user; preserve exact coordinates,
-- orientation and name. Antu'sul has a normal native dungeon boss spawn:
-- do not change combat AI or force a duplicate summon.
--
-- Preserve all manually configured Chaotic Link candidates and stack counts,
-- stage depths, weights, rewards and other segment settings.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2147, 1784.71, 809.753, 26.2688, 4.96922, 209,
     'Manastorm_ZulFarrak_Antu\'sul');

-- Disable only the recovered alternative Antu'sul routes; keep their
-- original records intact for historical catalogue preservation.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 209
  AND `objective_creature_entry` = 8127
  AND (
      (`segment_id` IN (194, 195, 196)
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 595)
   OR (`segment_id` IN (397, 398, 399)
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2595)
  );

-- StartingUnlocked (0x1). One recovered route per track.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2147,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 193
     AND `map_id` = 209
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 595
     AND `objective_creature_entry` = 8127
     AND `start_game_tele_id` IN (0, 2147))
 OR (`segment_id` = 396
     AND `map_id` = 209
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2595
     AND `objective_creature_entry` = 8127
     AND `start_game_tele_id` IN (0, 2147));

-- Verify the selected stages and disabled historical alternatives:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 209 AND objective_creature_entry = 8127
-- ORDER BY difficulty, segment_id;
