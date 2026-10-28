-- Uldaman / Galgann Firehammer (NPC 7291, map 70).
--
-- Restore exactly one original Ascension Manastorm route per difficulty:
--   496 = Normal,  dungeon encounter  552
--   510 = Endgame, dungeon encounter 2552
--
-- Original duplicate alternatives to leave in the catalogue, disabled:
--   599 = Normal (same native boss and encounter)
--   598 = Endgame (same native boss and encounter)
--
-- Exact player-authored start teleport:
--   id 2167, X -2.02528, Y 363.734, Z -43.0689,
--   orientation 1.53544, map 70,
--   'Manastorm_Uldaman_GalgannFireHammer'
--
-- Native instance_uldaman.cpp has no special altar/summoning/activation
-- event for Galgann. Use his normal AzerothCore DB spawn and combat AI.
-- The nearby Grimlok objective (4854) remains an independent segment.
--
-- Rerunnable and scoped only to these four historical segment IDs.
-- Preserve all existing Chaotic Link candidate rosters, stacks, weights,
-- depths, rewards, runtime identities, and unrelated boss configurations.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2167, -2.02528, 363.734, -43.0689, 1.53544, 70,
     'Manastorm_Uldaman_GalgannFireHammer');

-- Preserve unused native variants, but exclude them from weighted selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 70
  AND `objective_creature_entry` = 7291
  AND ((`segment_id` = 599
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 552)
    OR (`segment_id` = 598
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2552));

-- Baseline Uldaman boss. Preserve any other flags by OR-ing
-- StartingUnlocked (0x1), and do not alter weight/stack settings.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2167,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 496
     AND `map_id` = 70
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 552
     AND `objective_creature_entry` = 7291
     AND `start_game_tele_id` IN (0, 2167))
 OR (`segment_id` = 510
     AND `map_id` = 70
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2552
     AND `objective_creature_entry` = 7291
     AND `start_game_tele_id` IN (0, 2167));

-- Read-only verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        weight, chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 70 AND objective_creature_entry = 7291
-- ORDER BY difficulty, segment_id;
