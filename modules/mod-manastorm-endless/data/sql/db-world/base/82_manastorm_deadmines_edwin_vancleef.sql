-- Deadmines / Edwin VanCleef.
--
-- Restore one Normal and one Endgame Manastorm segment with the same physical
-- start location as Captain Greenskin, but a separate named teleport.
--
-- Recovered native identities:
--   129 = Normal,  map 36, encounter 167,  objective 639
--   551 = Endgame, map 36, encounter 2167, objective 639
--   Unused Normal variant: 550
--
-- User-authorized game_tele 2122, map 36:
--   -100.544, -791.458, 17.0539, orientation 3.18791
--
-- Reuse Captain Greenskin's ACTUAL authored Chaotic Link candidates/counts:
--   Greenskin Normal 126 -> VanCleef Normal 129
--   Greenskin Endgame 228 -> VanCleef Endgame 551
--
-- IMPORTANT: run/re-run this script AFTER Greenskin's links and stacks have
-- been configured in the world DB. This is an SQL snapshot/copy, not a live
-- ongoing synchronization of later GM changes.
-- The copy is idempotent: preserve other existing destination spawn roles.
-- A VanCleef (entry 639) spawn is never valid as its own Chaotic Link.
--
-- The reciprocal removal of nearby Captain Greenskin from VanCleef's private
-- instance is implemented in ManastormDeadminesCompat.cpp.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2122, -100.544, -791.458, 17.0539, 3.18791, 36,
     'Manastorm_Deadmines_EdwinVanCleef');

-- Keep the redundant native Normal route, but not in the selection pool.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 36
  AND `objective_creature_entry` = 639
  AND `segment_id` = 550;

-- Baseline dungeon content (StartingUnlocked 0x1).
-- Do not touch existing weights, manual links, or other stage tuning.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2122,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 129
     AND `map_id` = 36
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 167
     AND `objective_creature_entry` = 639
     AND `start_game_tele_id` IN (0, 2122))
 OR (`segment_id` = 551
     AND `map_id` = 36
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2167
     AND `objective_creature_entry` = 639
     AND `start_game_tele_id` IN (0, 2122));

-- Copy only the authored Chaotic Link route role (0x01 | 0x02),
-- rather than unrelated randomization / pool / affix roles.
-- Join the actual creature DB to reject stale IDs and VanCleef himself.
-- Existing destination roles remain intact on duplicate spawn GUIDs.
INSERT INTO `manastorm_segment_spawn`
    (`segment_id`, `spawn_guid`, `flags`, `enabled`)
SELECT
    CASE `src`.`segment_id`
        WHEN 126 THEN 129
        WHEN 228 THEN 551
    END,
    `src`.`spawn_guid`,
    3,
    1
FROM `manastorm_segment_spawn` AS `src`
INNER JOIN `creature` AS `c`
    ON `c`.`guid` = `src`.`spawn_guid`
   AND `c`.`map` = 36
   AND `c`.`id` <> 639
WHERE `src`.`segment_id` IN (126, 228)
  AND `src`.`enabled` = 1
  AND (`src`.`flags` & 2) <> 0
ON DUPLICATE KEY UPDATE
    `flags` = (`manastorm_segment_spawn`.`flags` | 3),
    `enabled` = 1;

-- Match the required stack count from each corresponding Greenskin stage.
-- Never raise it beyond the valid number of copied active candidates.
-- If Greenskin's links have not yet been authored, rerun this migration
-- AFTER authoring them; the diagnostic SELECT below reveals mismatches.
UPDATE `manastorm_segment` AS `dst`
INNER JOIN `manastorm_segment` AS `src`
    ON (`src`.`segment_id` = 126 AND `dst`.`segment_id` = 129)
    OR (`src`.`segment_id` = 228 AND `dst`.`segment_id` = 551)
SET `dst`.`chaotic_link_stacks` = `src`.`chaotic_link_stacks`
WHERE `src`.`map_id` = 36
  AND `dst`.`map_id` = 36
  AND `dst`.`objective_creature_entry` = 639
  AND `src`.`objective_creature_entry` = 647
  AND `src`.`chaotic_link_stacks` <= (
      SELECT COUNT(*)
      FROM `manastorm_segment_spawn` AS `links`
      WHERE `links`.`segment_id` = `dst`.`segment_id`
        AND `links`.`enabled` = 1
        AND (`links`.`flags` & 2) <> 0
  );

-- Compare candidate counts and required stacks, Normal then Endgame.
-- Both pairs should match after successful link copying.
SELECT
    `s`.`segment_id`,
    `s`.`difficulty`,
    `s`.`objective_creature_entry`,
    `s`.`start_game_tele_id`,
    `s`.`chaotic_link_stacks`,
    COUNT(`spawn`.`spawn_guid`) AS `chaotic_link_candidates`,
    `s`.`enabled`
FROM `manastorm_segment` AS `s`
LEFT JOIN `manastorm_segment_spawn` AS `spawn`
    ON `spawn`.`segment_id` = `s`.`segment_id`
   AND `spawn`.`enabled` = 1
   AND (`spawn`.`flags` & 2) <> 0
WHERE `s`.`segment_id` IN (126, 129, 228, 551)
GROUP BY
    `s`.`segment_id`,
    `s`.`difficulty`,
    `s`.`objective_creature_entry`,
    `s`.`start_game_tele_id`,
    `s`.`chaotic_link_stacks`,
    `s`.`enabled`
ORDER BY FIELD(`s`.`segment_id`, 126, 129, 228, 551);
