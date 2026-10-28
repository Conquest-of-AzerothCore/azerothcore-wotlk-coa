-- Maraudon / Razorlash (native NPC 12258, map 349).
--
-- Original Ascension Manastorm identities:
--   434 = Normal  (difficulty 0), dungeon encounter 423
--   453 = Endgame (difficulty 2), dungeon encounter 2423
-- These are the only recovered Razorlash segments: one per difficulty.
-- Do not create or disable any other historical route.
--
-- Exact user-authored start teleport:
--   game_tele 2173, map 349
--   X 963.138, Y -180.511, Z -65.6082, orientation 2.94134
--   'Manastorm_Maraudon_Razorlash'
--
-- Native instance_maraudon.cpp only implements Noxxion-specific
-- Corruption Spewer progression; Razorlash is not gated by it.
-- Leave the native Razorlash spawn, combat AI and public Maraudon
-- behavior untouched. No C++ encounter bootstrap is required.
--
-- Idempotent. Preserve manually authored Chaotic Link creature
-- candidates/stacks, weights, depth policies, reward multipliers
-- and all other existing flags.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2173, 963.138, -180.511, -65.6082, 2.94134, 349,
     'Manastorm_Maraudon_Razorlash');

-- Enable the two original route identities and only assign the
-- authored teleport plus StartingUnlocked (bit 0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2173,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 434
     AND `map_id` = 349
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 423
     AND `objective_creature_entry` = 12258
     AND `start_game_tele_id` IN (0, 2173))
 OR (`segment_id` = 453
     AND `map_id` = 349
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2423
     AND `objective_creature_entry` = 12258
     AND `start_game_tele_id` IN (0, 2173));

-- Read-only verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        weight, chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE segment_id IN (434, 453)
-- ORDER BY difficulty, segment_id;
