-- Blackrock Depths / Magmus (native NPC 9938, map 230).
--
-- Recovered original Ascension Manastorm routes:
--   428 = Normal  (difficulty 0), dungeon encounter  244
--   457 = Endgame (difficulty 2), dungeon encounter 2244
-- Duplicate original Normal routes to retain but disable:
--   429, 430 (both difficulty 0, dungeon encounter 244)
-- There is no alternate recovered Endgame route.
--
-- Exact player-authored arrival teleport (not a creature spawn):
--   2187, X 1316.93, Y -345.918, Z -92.0424,
--   orientation 5.40745, map 230,
--   'Manastorm_BlackrockDepths_Magmus'
--
-- Native boss_magmus.cpp uses TYPE_IRON_HALL and retains its War
-- Stomp / Fiery Burst combat behavior. The native instance script
-- opens the throne door on his defeat; the separate Lyceum event
-- opens golem-room doors 170573/170574. Do not complete that
-- unrelated prerequisite globally or alter native instance state.
-- Verify in-game that the authored arrival can reach Magmus.
--
-- Rerunnable, guarded migration. Preserve Chaotic Link candidates
-- and stacks, weights, depths, rewards, and unrelated flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2187, 1316.93, -345.918, -92.0424, 5.40745, 230,
     'Manastorm_BlackrockDepths_Magmus');

-- Retain historical duplicate Normal records but disable selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 230
  AND `objective_creature_entry` = 9938
  AND `difficulty` = 0
  AND `dungeon_encounter_id` = 244
  AND `segment_id` IN (429, 430);

-- Enable one recovered original route per difficulty. OR
-- StartingUnlocked (0x1) without disturbing other flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2187,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 428
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 244
     AND `objective_creature_entry` = 9938
     AND `start_game_tele_id` IN (0, 2187))
 OR (`segment_id` = 457
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2244
     AND `objective_creature_entry` = 9938
     AND `start_game_tele_id` IN (0, 2187));

-- Read-only verification after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 9938
-- ORDER BY difficulty, segment_id;
