-- Blackfathom Deeps / Twilight Lord Kelris.
--
-- Recovered original Manastorm encounter identities (map 48, NPC 4832):
--   Normal:  75, dungeon encounter 225
--   Endgame: 242, dungeon encounter 2225
-- Unselected historical route variants, retained but disabled:
--   Normal 76; Endgame 243.
--
-- User-authored teleport preserved exactly, including capitalization:
--   2156, X -725.989, Y -64.7862, Z -30.0332, facing 2.82981,
--   map 48, 'Manastorm_BlackfathomDeep_TwilightLordKelris'.
--
-- Native encounter: the Blackfathom Deeps instance script does not
-- gate Kelris behind another boss, object, or event. The fire-event
-- gate is relevant to Aku'mai, not Kelris. Preserve the original
-- physical boss spawn, combat AI, and all native instance behavior.
--
-- Idempotent; preserve authored Chaotic Link rosters, stack requirements,
-- selection weights, depth thresholds, reward settings, and all flags
-- other than OR-ing in the StartingUnlocked bit (0x1).

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2156, -725.989, -64.7862, -30.0332, 2.82981, 48,
     'Manastorm_BlackfathomDeep_TwilightLordKelris');

-- Keep historical alternate original segments, but prevent selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 48
  AND `objective_creature_entry` = 4832
  AND (
      (`segment_id` = 76
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 225)
   OR (`segment_id` = 243
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2225)
  );

-- Select one original segment for each track. Do not alter live
-- Chaotic Links, stack requirements or any non-unlock flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2156,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 75
     AND `map_id` = 48
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 225
     AND `objective_creature_entry` = 4832
     AND `start_game_tele_id` IN (0, 2156))
 OR (`segment_id` = 242
     AND `map_id` = 48
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2225
     AND `objective_creature_entry` = 4832
     AND `start_game_tele_id` IN (0, 2156));

-- Read-only verification, including disabled original variants:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 48 AND objective_creature_entry = 4832
-- ORDER BY difficulty, segment_id;
