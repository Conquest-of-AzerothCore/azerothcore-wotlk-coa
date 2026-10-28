-- Scarlet Monastery / Houndmaster Loksey (Library).
--
-- Recovered native Manastorm identities (map 189, objective 3974):
--   107 = Normal,  encounter 446
--   312 = Endgame, encounter 2446
--   No alternative native Loksey routes in the recovered catalogue.
--
-- User-authored starting teleport:
--   2131, map 189, X 269.625, Y -217.749, Z 19.2011,
--   orientation 4.71946
--
-- Preserve any existing manually authored Chaotic Link candidates, required
-- stack counts, weights, depth settings, rewards and other segment tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2131, 269.625, -217.749, 19.2011, 4.71946, 189,
     'Manastorm_ScarletMonastery_HoundmasterLoksey');

-- Baseline dungeon availability: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2131,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 107
     AND `map_id` = 189
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 446
     AND `objective_creature_entry` = 3974
     AND `start_game_tele_id` IN (0, 2131))
 OR (`segment_id` = 312
     AND `map_id` = 189
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2446
     AND `objective_creature_entry` = 3974
     AND `start_game_tele_id` IN (0, 2131));

-- Verify the two selected native stages:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 189 AND objective_creature_entry = 3974
-- ORDER BY segment_id;
