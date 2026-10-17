-- Maraudon / Landslide (native NPC 12203, map 349).
--
-- Recovered original Ascension Manastorm routes:
--   436 = Normal  (difficulty 0), dungeon encounter  426
--   450 = Endgame (difficulty 2), dungeon encounter 2426
-- Duplicate alternative routes for exactly the same boss:
--   437 = alternate Normal; retain disabled
--   451 = alternate Endgame; retain disabled
--
-- Exact player-authored arrival teleport:
--   ID 2175, X 153.085, Y -265.168, Z -108.676,
--   orientation 1.60693, map 349,
--   'Manastorm_Maraudon_Landslide'
--
-- Native instance_maraudon.cpp does not implement a Landslide-specific
-- activation or unlock prerequisite (only Noxxion's corruption spewer).
-- Preserve Landslide's existing native DB spawn, AI and boss mechanics.
--
-- Idempotent, scoped to recovered segment identities. Preserve
-- user-authored Chaotic Link candidates and stacks, stage weight/depth,
-- reward settings, unrelated flags, and other encounter routes.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2175, 153.085, -265.168, -108.676, 1.60693, 349,
     'Manastorm_Maraudon_Landslide');

-- Keep duplicate historical routes in the catalogue, but ineligible
-- for ordinary Manastorm weighted stage selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 349
  AND `objective_creature_entry` = 12203
  AND ((`segment_id` = 437
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 426)
    OR (`segment_id` = 451
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2426));

-- Enable one original route per difficulty, sharing the player's
-- teleport. OR StartingUnlocked bit 0x1, preserving other flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2175,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 436
     AND `map_id` = 349
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 426
     AND `objective_creature_entry` = 12203
     AND `start_game_tele_id` IN (0, 2175))
 OR (`segment_id` = 450
     AND `map_id` = 349
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2426
     AND `objective_creature_entry` = 12203
     AND `start_game_tele_id` IN (0, 2175));

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 349 AND objective_creature_entry = 12203
-- ORDER BY difficulty, segment_id;
