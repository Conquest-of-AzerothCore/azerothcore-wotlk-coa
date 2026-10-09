-- Razorfen Kraul / Charlga Razorflank.
--
-- Restore one Normal and one Endgame Manastorm segment for the original
-- Razorfen Kraul objective while preserving unused native alternate routes.
--
-- Recovered Manastorm identities:
--    89 = Normal,  map 47, encounter 443,  objective 4421
--   306 = Endgame, map 47, encounter 2443, objective 4421
--
-- Unused native variants:
--    90 = Normal alternate
--   307 = Endgame alternate
--
-- User-authored start:
--   game_tele 2128, map 47
--   X 2203.16, Y 1905.95, Z 70.4997, orientation 4.45636
--   Name deliberately matches the supplied game_tele INSERT.
--
-- Preserve manually authored Chaotic Link candidates, stack counts,
-- segment weights, native identities and all unrelated tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2128, 2203.16, 1905.95, 70.4997, 4.45636, 47,
     'Manastorm_RazorfenKraul_CharigaRazorflank');

-- Keep the original catalogue rows but exclude redundant routes.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 47
  AND `objective_creature_entry` = 4421
  AND `segment_id` IN (90, 307);

-- Baseline dungeon availability: StartingUnlocked bit 0x1.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2128,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 89
     AND `map_id` = 47
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 443
     AND `objective_creature_entry` = 4421
     AND `start_game_tele_id` IN (0, 2128))
 OR (`segment_id` = 306
     AND `map_id` = 47
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2443
     AND `objective_creature_entry` = 4421
     AND `start_game_tele_id` IN (0, 2128));

-- Verify:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 47 AND objective_creature_entry = 4421
-- ORDER BY segment_id;
