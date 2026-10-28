-- Maraudon / Lord Vyletongue (native NPC 12236, map 349).
--
-- Recovered Ascension Manastorm routes:
--   206 = Normal (difficulty 0), dungeon encounter 424
--   285 = Endgame (difficulty 2), dungeon encounter 2424
-- Alternate routes for this SAME boss/encounter remain catalogued but disabled:
--   207 = Normal alternate
--   286 = Endgame alternate
-- One enabled boss route per difficulty; never invent additional tracks.
--
-- Exact user-authored arrival teleport, including spelling/capitalization:
--   game_tele ID 2171, map 349
--   X 635.174, Y -281.682, Z -53.2722, orientation 1.67682
--   name 'Manastorm_Maraudon_LordVylentongue'
--
-- Native instance_maraudon.cpp has no Vyletongue activation, summoning,
-- or prerequisite event. His NPC 12236 is an ordinary native boss spawn;
-- keep the original AzerothCore DB creature and combat behavior.
--
-- Safe to rerun. Do not touch manually curated Chaotic Link candidate
-- rosters/stacks, boss scaling, segment weights, depths, rewards,
-- unrelated flags or other dungeon encounters.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2171, 635.174, -281.682, -53.2722, 1.67682, 349,
     'Manastorm_Maraudon_LordVylentongue');

-- Preserve historical alternate routes while making them ineligible
-- for ordinary weighted selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 349
  AND `objective_creature_entry` = 12236
  AND ((`segment_id` = 207
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 424)
    OR (`segment_id` = 286
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2424));

-- Enable one original route per difficulty with the shared start
-- teleport. OR StartingUnlocked (0x1) without replacing other flags.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2171,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 206
     AND `map_id` = 349
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 424
     AND `objective_creature_entry` = 12236
     AND `start_game_tele_id` IN (0, 2171))
 OR (`segment_id` = 285
     AND `map_id` = 349
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2424
     AND `objective_creature_entry` = 12236
     AND `start_game_tele_id` IN (0, 2171));

-- Read-only verification after import:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 349 AND objective_creature_entry = 12236
-- ORDER BY difficulty, segment_id;
