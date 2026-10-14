-- Uldaman / Obsidian Sentinel (native NPC 7023, map 70).
--
-- Preserve recovered Ascension Manastorm segment identities:
--    595 = Normal  (difficulty 0), dungeon encounter 2172
--    594 = Endgame (difficulty 2), dungeon encounter 2617
-- The recovered source contains exactly one route per difficulty.
-- Do not manufacture alternate paths or replace historical encounter IDs.
--
-- Exact player-authored arrival teleport:
--   2169, X -87.8907, Y 305.863, Z -50.82,
--   orientation 2.25568, map 70,
--   name 'Manastorm_Uldaman_ObsidianSentinel'
--
-- Obsidian Sentinel is a native rear-entrance boss; preserve his
-- existing spell reflection / split-at-health-threshold combat behavior.
-- instance_uldaman.cpp contains no special boss activation event
-- for creature 7023, so no Manastorm-only summon or awakening hook is
-- required. Leave all door/object scripts unchanged.
--
-- Rerunnable and narrowly scoped. Retain original Chaotic Link candidate
-- lists and stack counts, stage weights, depths, rewards, and all other
-- flag bits. Enable only these two recovered baseline boss segments.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2169, -87.8907, 305.863, -50.82, 2.25568, 70,
     'Manastorm_Uldaman_ObsidianSentinel');

-- Only set the shared teleport, StartingUnlocked (bit 0x1), and enabled.
-- Do not replace unrelated flags or manually configured combat settings.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2169,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 595
     AND `map_id` = 70
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 2172
     AND `objective_creature_entry` = 7023
     AND `start_game_tele_id` IN (0, 2169))
 OR (`segment_id` = 594
     AND `map_id` = 70
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2617
     AND `objective_creature_entry` = 7023
     AND `start_game_tele_id` IN (0, 2169));

-- Read-only verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        weight, chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE segment_id IN (594, 595)
-- ORDER BY difficulty, segment_id;
