-- Dire Maul North / Guard Fengus.
--
-- Recovered native Manastorm identities (map 429, objective 14321):
--   137 = Normal
--   273 = Endgame
--
-- Guard Fengus patrols normally in the Gordok courtyard. His native
-- creature spawn (248079) and AI/movement must remain untouched.
-- No forced summon, respawn override, or tribute-mechanic changes.
--
-- User-authored starting teleport (exact values and name):
--   2143, map 429, X 385.218, Y 368.283, Z 0.0386634,
--   orientation 4.68962
--
-- Original Manastorm dungeon_encounter_id values for these North-wing
-- segments have not been verified. Preserve the native existing values.
-- Preserve Chaotic Link spawn candidates, stack counts, weights, depths,
-- rewards, and all other authored settings.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2143, 385.218, 368.283, 0.0386634, 4.68962, 429,
     'Manastorm_DireMaul_GuardFengus');

-- Keep unselected historical Normal/Endgame routes without offering them
-- to random Manastorm selection. Do not delete or rewrite native records.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 429
  AND `objective_creature_entry` = 14321
  AND `difficulty` IN (0, 2)
  AND `segment_id` NOT IN (137, 273);

-- Enable exactly one recovered Normal and one Endgame original.
-- StartingUnlocked (0x1), consistent with preceding Dire Maul stages.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2143,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 137
     AND `map_id` = 429
     AND `difficulty` = 0
     AND `objective_creature_entry` = 14321
     AND `start_game_tele_id` IN (0, 2143))
 OR (`segment_id` = 273
     AND `map_id` = 429
     AND `difficulty` = 2
     AND `objective_creature_entry` = 14321
     AND `start_game_tele_id` IN (0, 2143));

-- Verify both selected routes and any disabled historical alternatives:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 429 AND objective_creature_entry = 14321
-- ORDER BY difficulty, segment_id;
