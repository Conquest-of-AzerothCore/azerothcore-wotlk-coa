-- Dire Maul West / Immol'thar.
--
-- Recovered native Manastorm identities (map 429, objective 11496):
--   686 = Normal,  encounter 349
--   685 = Endgame, encounter 2349
--   No alternative native Immol'thar objective routes in the recovered catalogue.
--
-- User-authored starting teleport (name preserved exactly as supplied):
--   2140, map 429, X -38.5599, Y 609.762, Z -23.3052,
--   orientation 1.55353
--
-- The native boss is protected by the five Dire Maul West pylons.
-- ManastormDireMaulCompat.cpp releases the native encounter only in
-- selected disposable private Manastorm stages; normal Dire Maul is unaffected.
--
-- Preserve existing Chaotic Link candidates, stack counts, weights, depth,
-- reward tuning, and all manually authored stage settings.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2140, -38.5599, 609.762, -23.3052, 1.55353, 429,
     'Manastorm_DireMaul_Immol\'thar');

-- Baseline dungeon eligibility: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2140,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 686
     AND `map_id` = 429
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 349
     AND `objective_creature_entry` = 11496
     AND `start_game_tele_id` IN (0, 2140))
 OR (`segment_id` = 685
     AND `map_id` = 429
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2349
     AND `objective_creature_entry` = 11496
     AND `start_game_tele_id` IN (0, 2140));

-- Verify:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 429 AND objective_creature_entry = 11496
-- ORDER BY segment_id;
