-- Razorfen Downs / Glutton.
--
-- Original recovered Ascension Manastorm identities (map 129, NPC 8567):
--    95 = Normal, dungeon encounter 436
--   298 = Endgame, dungeon encounter 2436
-- Retain but disable the alternate historical routes:
--    96 (Normal) and 299 (Endgame).
--
-- Exact user-authored start teleport:
--   2160, X 2455.48, Y 867.41, Z 35.2933, orientation 1.18046,
--   map 129, 'Manastorm_RazorfenDowns_Glutton'.
--
-- Glutton is a native standing dungeon encounter. The Razorfen Downs
-- instance and creature scripts do not gate entry 8567 behind the
-- gong or Belnistrasz event. Retain existing spawn and combat AI.
-- This is a rerunnable world-SQL update. Preserve manually configured
-- Chaotic Link candidates/stacks, other flags, weights, depths and rewards.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2160, 2455.48, 867.41, 35.2933, 1.18046, 129,
     'Manastorm_RazorfenDowns_Glutton');

-- Disable only the original unselected Glutton variants.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 129
  AND `objective_creature_entry` = 8567
  AND (
      (`segment_id` = 96
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 436)
   OR (`segment_id` = 299
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2436)
  );

-- Select exactly one original route per track.
-- StartingUnlocked = bit 0x1; preserve every other flag bit.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2160,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 95
     AND `map_id` = 129
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 436
     AND `objective_creature_entry` = 8567
     AND `start_game_tele_id` IN (0, 2160))
 OR (`segment_id` = 298
     AND `map_id` = 129
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2436
     AND `objective_creature_entry` = 8567
     AND `start_game_tele_id` IN (0, 2160));

-- Verify original routes after importing (read-only):
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 129 AND objective_creature_entry = 8567
-- ORDER BY difficulty, segment_id;
