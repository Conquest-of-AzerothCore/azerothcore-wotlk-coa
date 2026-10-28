-- Deadmines / Mr. Smite.
--
-- Restore exactly one Normal and one Endgame Manastorm segment using the
-- user-authorized start position. Leave extra native route variants disabled.
--
-- Recovered Manastorm identities:
--   122 = Normal,  map 36, encounter 164,  objective 646
--   222 = Endgame, map 36, encounter 2164, objective 646
--
-- Unused native variants:
--   Normal:  123, 124
--   Endgame: 224
--
-- User-authored starting teleport:
--   game_tele 2119, map 36
--   -98.3633, -677.416, 7.42321, orientation 4.80271
--
-- Preserve Chaotic Link candidate selections, stack requirements, weights,
-- encounter identities, and all other existing segment tuning.
-- Mr. Smite has a native scripted weapon-switch mechanic. Retain the stock
-- Deadmines encounter script; test it within the disposable Manastorm stage.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2119, -98.3633, -677.416, 7.42321, 4.80271, 36,
     'Manastorm_Deadmines_MrSmite');

-- Preserve recovered alternate routes but do not select them.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 36
  AND `objective_creature_entry` = 646
  AND `segment_id` IN (123, 124, 224);

-- Baseline dungeon content: StartingUnlocked (bit 0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2119,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 122
     AND `map_id` = 36
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 164
     AND `objective_creature_entry` = 646
     AND `start_game_tele_id` IN (0, 2119))
 OR (`segment_id` = 222
     AND `map_id` = 36
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2164
     AND `objective_creature_entry` = 646
     AND `start_game_tele_id` IN (0, 2119));

-- Verify:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 36 AND objective_creature_entry = 646
-- ORDER BY segment_id;
