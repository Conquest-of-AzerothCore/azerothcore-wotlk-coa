-- Blackfathom Deeps / Aku'mai: final recovered dungeon objective.
--
-- Original Manastorm identities (map 48, NPC 4829):
--   81  = Normal,  encounter 226
--   244 = Endgame, encounter 2226
-- No alternate Aku'mai segment variants in the recovered catalogue.
--
-- Exact in-game teleport authored by the user:
-- 2157, X -817.61, Y -211.539, Z -25.8713, facing 4.70299,
-- map 48, 'Manastorm_BlackfathhomDeep_Aku\'mai'
--
-- In regular BFD, the native four-fire wave event opens GO 21117.
-- The module's ManastormBlackfathomDeepsCompat.cpp opens only that
-- ORIGINAL door in isolated private Manastorm instances during 81/244.
-- It also loads the original DB boss spawn's grid without replacing
-- the creature or modifying the ordinary BFD instance event state.
--
-- Preserve the native boss AI, all player-authored Chaotic Link
-- candidates/required stacks, selection weights, reward multipliers,
-- depths and other original segment flags.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2157, -817.61, -211.539, -25.8713, 4.70299, 48,
     'Manastorm_BlackfathhomDeep_Aku\'mai');

-- Enable the two verified original Manastorm rows, one per track.
-- Add StartingUnlocked flag 0x1 without disturbing other bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2157,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 81
     AND `map_id` = 48
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 226
     AND `objective_creature_entry` = 4829
     AND `start_game_tele_id` IN (0, 2157))
 OR (`segment_id` = 244
     AND `map_id` = 48
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2226
     AND `objective_creature_entry` = 4829
     AND `start_game_tele_id` IN (0, 2157));

-- Verify both original Aku'mai segment identities:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 48 AND objective_creature_entry = 4829
-- ORDER BY difficulty, segment_id;
