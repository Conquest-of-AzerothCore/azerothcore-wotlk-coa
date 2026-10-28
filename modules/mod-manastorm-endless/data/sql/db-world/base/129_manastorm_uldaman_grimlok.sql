-- Uldaman / Grimlok (native NPC 4854, map 70).
--
-- Recovered Ascension Manastorm identities:
--   383 = Endgame (difficulty 2), dungeon encounter 2553
--   596 = alternate Endgame route, same boss/encounter: keep disabled
-- There is NO recovered Normal (difficulty 0) Grimlok segment.
-- Do not invent a corresponding Normal segment or encounter identity.
--
-- Player-authored start teleport, preserved exactly:
--   game_tele 2166, map 70,
--   X 13.6905, Y 358.026, Z -43.2501, O 0.279616
--   'Manastorm_uldaman_Grimlok'
--
-- This boss has no special encounter activation logic in the native
-- AzerothCore instance_uldaman script. Preserve ordinary native
-- creature spawning, AI and any accompanying mobs in private Manastorm.
--
-- Scoped and idempotent. Preserve authored Chaotic Link candidate
-- rosters, stacks, weight, min/max depth, reward multipliers and
-- all independent segment IDs. Only the selected route is activated.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2166, 13.6905, 358.026, -43.2501, 0.279616, 70,
     'Manastorm_uldaman_Grimlok');

-- Preserve unused native variant as a disabled historical row.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `segment_id` = 596
  AND `map_id` = 70
  AND `difficulty` = 2
  AND `dungeon_encounter_id` = 2553
  AND `objective_creature_entry` = 4854;

-- Native Endgame segment 383 is the sole eligible Grimlok route.
-- OR StartingUnlocked (bit 0x1) without replacing existing flags.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2166,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE `segment_id` = 383
  AND `map_id` = 70
  AND `difficulty` = 2
  AND `dungeon_encounter_id` = 2553
  AND `objective_creature_entry` = 4854
  AND `start_game_tele_id` IN (0, 2166);

-- Read-only verification after import:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE segment_id IN (383, 596)
-- ORDER BY segment_id;
