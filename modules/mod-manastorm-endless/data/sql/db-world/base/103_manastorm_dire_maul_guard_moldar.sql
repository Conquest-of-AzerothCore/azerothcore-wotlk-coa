-- Dire Maul North / Guard Mol'dar.
--
-- Recovered native Manastorm identities (map 429, objective 14326):
--   133 = Normal
--   269 = Endgame
--
-- The original dungeon_encounter_id values for these North-wing rows
-- have not yet been independently recovered. Leave them untouched;
-- avoid guessing encounter numbers from another Dire Maul objective.
--
-- User-authored start teleport (verbatim values and name):
--   2142, map 429, X 270.594, Y -28.71, Z -2.56094, orientation 0.136654
--
-- Keep original route candidates, Chaotic Link stacks, depths, weights,
-- reward tuning, and any other manually authored stage fields unchanged.
-- No boss-spawn or tribute-state overrides: Guard Mol'dar is native.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2142, 270.594, -28.71, -2.56094, 0.136654, 429,
     'Manastorm_DireMaul_GuardMol\'dar');

-- Keep unselected alternative Normal/Endgame routes in the catalogue
-- without allowing them to enter random stage selection.
-- Scope by map, actual objective, track and the two selected segment IDs.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 429
  AND `objective_creature_entry` = 14326
  AND `difficulty` IN (0, 2)
  AND `segment_id` NOT IN (133, 269);

-- Enable the two selected recovered originals; StartingUnlocked = 0x1.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2142,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 133
     AND `map_id` = 429
     AND `difficulty` = 0
     AND `objective_creature_entry` = 14326
     AND `start_game_tele_id` IN (0, 2142))
 OR (`segment_id` = 269
     AND `map_id` = 429
     AND `difficulty` = 2
     AND `objective_creature_entry` = 14326
     AND `start_game_tele_id` IN (0, 2142));

-- Verify that both selected rows were updated, inspect their native
-- encounter IDs, and review which historical alternatives were disabled:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 429 AND objective_creature_entry = 14326
-- ORDER BY difficulty, segment_id;
