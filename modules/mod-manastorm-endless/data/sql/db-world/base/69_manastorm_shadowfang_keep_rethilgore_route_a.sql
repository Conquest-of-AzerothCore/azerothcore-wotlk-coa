-- Shadowfang Keep / Rethilgore, route A (original UW Endless start).
--
-- Authored anchor supplied by the user:
--   game_tele 2038, map 33
--   -229.362, 2112.67, 76.8892, 5.88858
--
-- Recovered Manastorm.dbc identities for route-A candidate:
--   19  = Normal,  encounter 464,  Rethilgore (3914)
--   320 = Endgame, encounter 2464, Rethilgore (3914)
--
-- The current catalogue also contains four additional route variants per
-- track: 20-23 and 321-324. Their teleports and chaotic links require
-- independent in-game authoring; do not assign them all to this one anchor.
--
-- Keep already-authored Chaotic Link counts, spawn links, encounter identity,
-- weights and other segment settings unchanged. The original first SFK
-- encounter is baseline starting content (StartingUnlocked bit 0x1).

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2038, -229.362, 2112.67, 76.8892, 5.88858, 33,
     'UWES_SFK_RETHILGORE_A');

UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2038,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 19 AND `map_id` = 33
        AND `difficulty` = 0 AND `dungeon_encounter_id` = 464
        AND `objective_creature_entry` = 3914
        AND `start_game_tele_id` IN (0, 2038))
    OR
    (`segment_id` = 320 AND `map_id` = 33
        AND `difficulty` = 2 AND `dungeon_encounter_id` = 2464
        AND `objective_creature_entry` = 3914
        AND `start_game_tele_id` IN (0, 2038));

-- Verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE segment_id IN (19, 320);
