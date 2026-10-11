-- Dire Maul North / King Gordok — final original Manastorm objective.
--
-- Recovered original Manastorm identities (map 429, objective 11501):
--   148 = Normal
--   279 = Endgame
--
-- The selected teleport lies on/near Captain Kromcrush's native spawn.
-- ManastormMgr.cpp + ManastormDireMaulCompat.cpp suppress creature 14325
-- only in King Gordok's private Manastorm stages, including late grid loads.
-- Do not kill the Captain, change dungeon tribute progression, or alter
-- normal Dire Maul and Kromcrush's own objective segments (147 / 278).
--
-- Exact user-authored starting teleport (name and numbers preserved):
--   2146, map 429, X 626.547, Y 482.21, Z 29.4655,
--   orientation 6.25684, name Manastorm_DireMaul_KingGordok
--
-- Keep recovered dungeon_encounter_id values unchanged: the original
-- Manastorm North-wing encounter numbers are not independently verified.
-- Preserve Chaotic Link routes, stacks, weights, depths and reward tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2146, 626.547, 482.21, 29.4655, 6.25684, 429,
     'Manastorm_DireMaul_KingGordok');

-- Keep unselected historical routes but exclude them from selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 429
  AND `objective_creature_entry` = 11501
  AND `difficulty` IN (0, 2)
  AND `segment_id` NOT IN (148, 279);

-- StartingUnlocked (bit 0x1): one original Normal and Endgame route.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2146,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 148
     AND `map_id` = 429
     AND `difficulty` = 0
     AND `objective_creature_entry` = 11501
     AND `start_game_tele_id` IN (0, 2146))
 OR (`segment_id` = 279
     AND `map_id` = 429
     AND `difficulty` = 2
     AND `objective_creature_entry` = 11501
     AND `start_game_tele_id` IN (0, 2146));

-- Verify the selected originals, encounter IDs and disabled alternatives:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 429 AND objective_creature_entry = 11501
-- ORDER BY difficulty, segment_id;
