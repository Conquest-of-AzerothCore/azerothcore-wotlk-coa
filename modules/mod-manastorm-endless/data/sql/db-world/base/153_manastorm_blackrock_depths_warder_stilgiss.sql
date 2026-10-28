-- Blackrock Depths / Warder Stilgiss (native NPC 9041, map 230).
--
-- Recovered original Ascension Manastorm routes:
--   698 = Normal  (difficulty 0), dungeon encounter  233
--   697 = Endgame (difficulty 2), dungeon encounter 2233
-- No duplicate historical Stilgiss routes were recovered.
--
-- Exact player-authored arrival teleport (not a creature spawn):
--   2190, X 897.755, Y -330.854, Z -49.6744,
--   orientation 1.614, map 230,
--   'Manastorm_BlackRockDepths_WarderStilgiss'
--
-- The native BRD instance script has no Stilgiss-specific gate,
-- scripted summoning, or activation prerequisite. Its separate
-- 12-coffer vault event summons Watchman Doomgrip (NPC 9476), not
-- Warder Stilgiss. Do not trigger that event or duplicate the
-- original DB creature spawn.
--
-- Rerunnable migration guarded by exact original segment IDs.
-- Preserve Chaotic Link candidates/stacks, stage weights/depths,
-- rewards, and unrelated flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2190, 897.755, -330.854, -49.6744, 1.614, 230,
     'Manastorm_BlackRockDepths_WarderStilgiss');

-- Enable one recovered original route per difficulty, preserving
-- all other flag bits by OR-ing StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2190,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 698
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 233
     AND `objective_creature_entry` = 9041
     AND `start_game_tele_id` IN (0, 2190))
 OR (`segment_id` = 697
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2233
     AND `objective_creature_entry` = 9041
     AND `start_game_tele_id` IN (0, 2190));

-- Read-only verification after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 9041
-- ORDER BY difficulty, segment_id;
