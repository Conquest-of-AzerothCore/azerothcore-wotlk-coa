-- Dire Maul North / Guard Slip'kik.
--
-- Recovered original Manastorm identities (map 429, objective 14323):
--   143 = Normal
--   276 = Endgame
--
-- Slip'kik has an optional repaired-trap interaction in the original
-- Gordok tribute run. This SQL does NOT activate the trap or alter the
-- boss's spawn, creature flags, patrol, combat AI, or dungeon mechanics.
-- Validate that he remains attackable in fresh private Manastorm tests.
--
-- User-authored starting teleport (exact values and name):
--   2144, map 429, X 460.972, Y 543.472, Z -23.9005,
--   orientation 0.00329122
--
-- Preserve original dungeon_encounter_id values because the North-wing
-- encounter IDs have not been independently verified. Preserve all
-- Chaotic Link routes, stack counts, weights, depth and reward settings.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2144, 460.972, 543.472, -23.9005, 0.00329122, 429,
     'Manastorm_DireMaul_GuardSlipKik');

-- Preserve but disable other Normal/Endgame variants for this objective.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 429
  AND `objective_creature_entry` = 14323
  AND `difficulty` IN (0, 2)
  AND `segment_id` NOT IN (143, 276);

-- Enable the chosen Normal and Endgame originals.
-- StartingUnlocked (0x1), as with the previous Dire Maul segments.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2144,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 143
     AND `map_id` = 429
     AND `difficulty` = 0
     AND `objective_creature_entry` = 14323
     AND `start_game_tele_id` IN (0, 2144))
 OR (`segment_id` = 276
     AND `map_id` = 429
     AND `difficulty` = 2
     AND `objective_creature_entry` = 14323
     AND `start_game_tele_id` IN (0, 2144));

-- Verify the two enabled original segments and retained alternatives:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 429 AND objective_creature_entry = 14323
-- ORDER BY difficulty, segment_id;
