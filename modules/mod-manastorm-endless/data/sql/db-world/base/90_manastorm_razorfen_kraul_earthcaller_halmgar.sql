-- Razorfen Kraul / Earthcaller Halmgar (rare objective).
--
-- The recovered Manastorm catalogue has one Endgame-only stage:
--   705 = map 47, difficulty 2, encounter 2615, objective 4842.
--
-- Do NOT invent a Normal Manastorm stage for this rare objective.
--
-- User-authored teleport:
--   game_tele 2129, map 47
--   X 2116.88, Y 1899.91, Z 71.1467, orientation 4.54198
--
-- Earth's original native DB spawn has a 12-hour respawn delay.
-- ManastormMgr's segment-705-only bootstrap revives/loads that original
-- spawn into the selected disposable private instance, without changing
-- Razorfen Kraul's ordinary/public spawn behavior.
--
-- Preserve existing Chaotic Link candidates, stack count, native identity,
-- weights and all other authored stage tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2129, 2116.88, 1899.91, 71.1467, 4.54198, 47,
     'Manastorm_RazorfenKraul_EarthcallerHalmgar');

-- Baseline dungeon availability: StartingUnlocked bit 0x1.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2129,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE `segment_id` = 705
  AND `map_id` = 47
  AND `difficulty` = 2
  AND `dungeon_encounter_id` = 2615
  AND `objective_creature_entry` = 4842
  AND `start_game_tele_id` IN (0, 2129);

-- Verify:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE segment_id = 705;
