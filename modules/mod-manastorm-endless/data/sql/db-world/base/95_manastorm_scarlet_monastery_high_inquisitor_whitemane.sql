-- Scarlet Monastery / High Inquisitor Whitemane (Cathedral).
--
-- Recovered native Manastorm identities (map 189, objective 3977):
--   528 = Normal,  encounter 450
--   532 = Endgame, encounter 2450
--   Unselected historical route: 530 (Normal, encounter 450).
--
-- Both stages share the user-authored teleport (preserved exactly):
--   2134, map 189, X 884.544, Y 1398.94, Z 18.6778,
--   orientation 0.0133445
--
-- ManastormScarletMonasteryCompat.cpp opens the outer Chapel Door
-- (GO 104591, spawn 11875) only for these disposable private stages.
-- Leave the inner High Inquisitor's Door (GO 104600, spawn 11877)
-- and the native Mograine 3976 -> Whitemane 3977 encounter untouched.
-- Only Whitemane's actual death completes the Manastorm objective.
--
-- Preserve manually authored Chaotic Link candidates and stack counts,
-- native identities, weights, depth, rewards and other stage tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2134, 884.544, 1398.94, 18.6778, 0.0133445, 189,
     'Manastorm_ScarletMonastery_HighInquisitorWhitemane');

-- Keep the original alternate route intact but out of selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `segment_id` = 530
  AND `map_id` = 189
  AND `difficulty` = 0
  AND `dungeon_encounter_id` = 450
  AND `objective_creature_entry` = 3977;

-- Baseline dungeon eligibility: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2134,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 528
     AND `map_id` = 189
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 450
     AND `objective_creature_entry` = 3977
     AND `start_game_tele_id` IN (0, 2134))
 OR (`segment_id` = 532
     AND `map_id` = 189
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2450
     AND `objective_creature_entry` = 3977
     AND `start_game_tele_id` IN (0, 2134));

-- Verify both selected stages and the disabled historical route:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 189 AND objective_creature_entry = 3977
-- ORDER BY segment_id;
