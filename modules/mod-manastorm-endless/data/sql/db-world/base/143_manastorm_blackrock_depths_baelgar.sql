-- Blackrock Depths / Bael'Gar (native NPC 9016, map 230).
--
-- Original recovered Ascension Manastorm routes:
--   417 = Normal  (difficulty 0), dungeon encounter  235
--   469 = Endgame (difficulty 2), dungeon encounter 2235
-- Duplicate original routes to retain but disable:
--   418 = alternate Normal; 470 = alternate Endgame
--
-- Exact player-authored arrival teleport:
--   2180, X 578.534, Y 18.8882, Z -71.0472,
--   orientation 0.535635, map 230,
--   "Manastorm_BlackrockDepths_Bael'Gar"
--
-- The current BRD instance and boss-script directory do not contain
-- Bael'Gar-specific activation, summoning, or door-unlock logic.
-- Leave existing native creature spawn and combat behavior unchanged.
--
-- Rerunnable and guarded by recovered segment identity. Preserve
-- Chaotic Link candidates/stacks, weights, depths, rewards, and flags
-- other than the StartingUnlocked bit on the selected original routes.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2180, 578.534, 18.8882, -71.0472, 0.535635, 230,
     'Manastorm_BlackrockDepths_Bael''Gar');

-- Historical duplicate routes remain in the database but ineligible.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 230
  AND `objective_creature_entry` = 9016
  AND ((`segment_id` = 418
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 235)
    OR (`segment_id` = 470
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2235));

-- Enable exactly one original route per difficulty. Set bit 0x1
-- (StartingUnlocked) without changing any other existing flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2180,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 417
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 235
     AND `objective_creature_entry` = 9016
     AND `start_game_tele_id` IN (0, 2180))
 OR (`segment_id` = 469
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2235
     AND `objective_creature_entry` = 9016
     AND `start_game_tele_id` IN (0, 2180));

-- Read-only verification after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 9016
-- ORDER BY difficulty, segment_id;
