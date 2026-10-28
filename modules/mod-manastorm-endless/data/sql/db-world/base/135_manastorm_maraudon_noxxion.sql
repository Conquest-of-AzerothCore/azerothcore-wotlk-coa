-- Maraudon / Noxxion (native NPC 13282, map 349).
--
-- Recovered Ascension Manastorm segments:
--    432 = Normal  (difficulty 0), dungeon encounter 422
--    454 = Endgame (difficulty 2), dungeon encounter 2422
-- Original alternate routes of the SAME native boss:
--    433 = Normal alternate; retain as disabled
--    455 = Endgame alternate; retain as disabled
--
-- Exact player-authored arrival teleport:
--    game_tele 2172, X 1052.01, Y -320.296, Z -72.562,
--    orientation 0.290621, map 349,
--    name 'Manastorm_Maraudon_Noxxion'
--
-- Noxxion has native Maraudon instance progression: once defeated,
-- TYPE_NOXXION (0) DONE permits the Corruption Spewer GO (178570)
-- to open. That GO is not a prerequisite to engage Noxxion himself.
-- Preserve the boss's existing spawn/combat AI and the normal
-- post-kill door behavior; no private-only bootstrap is required.
--
-- Idempotent, guarded by exact recovered identities. Never overwrite
-- existing Chaotic Link rosters/stacks, weights, depth policies,
-- reward multipliers, or other flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2172, 1052.01, -320.296, -72.562, 0.290621, 349,
     'Manastorm_Maraudon_Noxxion');

-- Keep recovered alternate routes in the catalogue but make them
-- ineligible for weighted segment selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 349
  AND `objective_creature_entry` = 13282
  AND ((`segment_id` = 433
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 422)
    OR (`segment_id` = 455
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2422));

-- Select one original Normal and one original Endgame Noxxion route.
-- Preserve all other flags via bitwise OR of StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2172,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 432
     AND `map_id` = 349
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 422
     AND `objective_creature_entry` = 13282
     AND `start_game_tele_id` IN (0, 2172))
 OR (`segment_id` = 454
     AND `map_id` = 349
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2422
     AND `objective_creature_entry` = 13282
     AND `start_game_tele_id` IN (0, 2172));

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 349 AND objective_creature_entry = 13282
-- ORDER BY difficulty, segment_id;
