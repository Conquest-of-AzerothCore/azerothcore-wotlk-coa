-- Stratholme / Maleki the Pallid (native NPC 10438, map 329).
--
-- Recovered original Ascension Manastorm routes:
--   154 = Normal  (difficulty 0), dungeon encounter  481
--   362 = Endgame (difficulty 2), dungeon encounter 2481
-- Duplicate historical routes to retain but disable:
--   155 = alternate Normal; 363 = alternate Endgame
--
-- Exact player-authored arrival teleport (not the native boss spawn):
--   2195, X 4070.8, Y -3539.52, Z 123.297,
--   orientation 2.41902, map 329,
--   'Manastorm_Stratholme_MalekithePallid'
--
-- Native Stratholme instance_stratholme.cpp uses TYPE_ZIGGURAT3
-- and the third ziggurat's door GO 175381 for post-boss dungeon
-- progression. Maleki himself has no native instance-script
-- summoning or activation prerequisite. Do not force ziggurat
-- progress or modify unrelated instance door/gameobject state.
--
-- IMPORTANT: Authored arrival is about four yards from the native
-- Barthilas relocation point (4068.74, -3535.97, 122.825).
-- Preserve the user's teleport exactly, but verify that Maleki
-- is reachable from it in the disposable Manastorm instance.
--
-- Rerunnable, guarded migration. Preserve original Chaotic Link
-- candidates/stacks, stage weights/depths, rewards, and unrelated
-- flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2195, 4070.8, -3539.52, 123.297, 2.41902, 329,
     'Manastorm_Stratholme_MalekithePallid');

-- Retain original duplicate rows for reference but disable them.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 329
  AND `objective_creature_entry` = 10438
  AND ((`segment_id` = 155
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 481)
    OR (`segment_id` = 363
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2481));

-- Exactly one original route per difficulty. OR StartingUnlocked
-- (0x1) without removing any preexisting flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2195,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 154
     AND `map_id` = 329
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 481
     AND `objective_creature_entry` = 10438
     AND `start_game_tele_id` IN (0, 2195))
 OR (`segment_id` = 362
     AND `map_id` = 329
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2481
     AND `objective_creature_entry` = 10438
     AND `start_game_tele_id` IN (0, 2195));

-- Read-only verification after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 329 AND objective_creature_entry = 10438
-- ORDER BY difficulty, segment_id;
