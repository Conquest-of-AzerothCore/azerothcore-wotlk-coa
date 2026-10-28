-- Razorfen Downs / Amnennar the Coldbringer.
--
-- Original recovered Ascension Manastorm segment identities
-- (map 129, objective NPC 7358):
--   650 = Normal,  dungeon encounter  437
--   651 = Endgame, dungeon encounter 2437
-- No unselected Amnennar variants in the recovered catalogue.
--
-- Exact player-authored start teleport (name/coordinates preserved):
--   2161, X 2421.5, Y 943.985, Z 45.2057, orientation 1.33523,
--   map 129, 'Manastorm_RazorfenDowns_AmnennartheColdbringer'
--
-- Amnennar is a persistent, native dungeon boss. The RFD instance
-- and encounter scripts do not require an unlocking/ritual phase for
-- this objective. Keep his existing world DB spawn and combat AI.
--
-- Only enable the two original segments and supply their arrival
-- game_tele; preserve manually configured Chaotic Link candidates and
-- stack counts, weights, depth thresholds, rewards and other flags.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2161, 2421.5, 943.985, 45.2057, 1.33523, 129,
     'Manastorm_RazorfenDowns_AmnennartheColdbringer');

-- Exactly one recovered stage per track; only OR StartingUnlocked
-- (0x1) into the existing flags, without overwriting other settings.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2161,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 650
     AND `map_id` = 129
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 437
     AND `objective_creature_entry` = 7358
     AND `start_game_tele_id` IN (0, 2161))
 OR (`segment_id` = 651
     AND `map_id` = 129
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2437
     AND `objective_creature_entry` = 7358
     AND `start_game_tele_id` IN (0, 2161));

-- Read-only post-import check:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 129 AND objective_creature_entry = 7358
-- ORDER BY difficulty, segment_id;
