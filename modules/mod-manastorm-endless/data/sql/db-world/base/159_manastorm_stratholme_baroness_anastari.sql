-- Stratholme / Baroness Anastari (native NPC 10436, map 329).
--
-- Recovered original Ascension Manastorm routes:
--   159 = Normal  (difficulty 0), dungeon encounter  479
--   359 = Endgame (difficulty 2), dungeon encounter 2479
-- No historical duplicate route exists for this boss.
--
-- Exact player-authored arrival teleport (not the boss spawn):
--   2196, X 3789.26, Y -3603.04, Z 144.789,
--   orientation 5.30143, map 329,
--   'Manastorm_Stratholme_BaronessAnastari'
--
-- Note: this arrival is about 3.4 yards from the previously
-- authored Nerub'enkan teleport 2194. Preserve the user's exact
-- location but confirm Baroness is reachable during GM tests.
--
-- Native boss_baroness_anastari.cpp handles Banshee Wail, Banshee
-- Curse, Silence, timed possession, and possession cleanup.
-- Her death marks TYPE_ZIGGURAT1 IN_PROGRESS, opening ziggurat
-- door 175380 as part of the original Stratholme event chain.
-- No special pre-combat spawn or unlock condition was found.
-- Do not force instance progression or alter native AI.
--
-- Rerunnable, guarded migration. Preserve original Chaotic Link
-- candidates/stacks, weights, depths, rewards, and unrelated flags.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2196, 3789.26, -3603.04, 144.789, 5.30143, 329,
     'Manastorm_Stratholme_BaronessAnastari');

-- Enable exactly one original route per difficulty. Add
-- StartingUnlocked (0x1) without clearing any existing flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2196,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 159
     AND `map_id` = 329
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 479
     AND `objective_creature_entry` = 10436
     AND `start_game_tele_id` IN (0, 2196))
 OR (`segment_id` = 359
     AND `map_id` = 329
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2479
     AND `objective_creature_entry` = 10436
     AND `start_game_tele_id` IN (0, 2196));

-- Read-only verification after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 329 AND objective_creature_entry = 10436
-- ORDER BY difficulty, segment_id;
