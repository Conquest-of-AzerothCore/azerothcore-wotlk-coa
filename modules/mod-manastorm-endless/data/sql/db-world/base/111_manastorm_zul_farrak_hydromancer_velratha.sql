-- Zul'Farrak / Hydromancer Velratha.
--
-- Recovered original Manastorm identities (map 209, objective 7795):
--   538 = Normal,  encounter 593
--   548 = Endgame, encounter 2593
--   Historical alternatives left disabled: 539 / 549.
--
-- User-authored teleport exactly matches the Ghaz'rilla entry (2149);
-- this is intentional: Velratha naturally patrols the same pool area.
--   2150, X 1706.51, Y 1161.51, Z 8.98762, facing 2.42067, map 209
--   'Manastorm_ZulFarrak_HydromancerVelratha'
--
-- Custom C++ keeps these stages independent:
--  * ManastormMgr.cpp loads and, if necessary, restores the native
--    persistent Velratha spawn at its REAL world DB coordinates.
--  * ManastormZulFarrakCompat.cpp disables the Gong of Zul'Farrak
--    (GO 141832, DB spawn 27140) in these private stages only.
--  * Ghaz'rilla (7273) is suppressed if added to Velratha's private stage.
-- No public Zul'Farrak world DB creature or gameobject is removed.
--
-- LIVE Chaotic Link COPY:
-- The user already configured links on Ghaz'rilla's two stages.
-- Copy only active RouteCreature|ChaoticLinkEligible roles from
--   198 -> 538 (Normal) and 392 -> 548 (Endgame).
-- CRITICAL: exclude any candidate whose native creature entry is the
-- destination segment's objective (Ghaz'rilla's links may include Velratha).
-- The target boss must never be a Chaotic Link to itself.
-- Do this from the ACTUAL server DB at SQL application time. Preserve
-- existing Velratha spawn roles and configured nonzero stack counts.
-- If sources are empty when this SQL runs, nothing can be copied:
-- re-run the copy below after authoring source links, before testing.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2150, 1706.51, 1161.51, 8.98762, 2.42067, 209,
     'Manastorm_ZulFarrak_HydromancerVelratha');

-- Preserve original variants but remove them from random selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE (`segment_id` = 539
       AND `map_id` = 209
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 593
       AND `objective_creature_entry` = 7795)
   OR (`segment_id` = 549
       AND `map_id` = 209
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2593
       AND `objective_creature_entry` = 7795);

-- One selected original per track; StartingUnlocked (bit 0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2150,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE (`segment_id` = 538
       AND `map_id` = 209
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 593
       AND `objective_creature_entry` = 7795
       AND `start_game_tele_id` IN (0, 2150))
   OR (`segment_id` = 548
       AND `map_id` = 209
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2593
       AND `objective_creature_entry` = 7795
       AND `start_game_tele_id` IN (0, 2150));

-- Clone exactly the active Ghaz'rilla CHAOTIC LINK candidate GUIDs,
-- not unrelated randomization slots or creature-pool source roles.
-- Keep any independent authored Velratha roles; OR in the two Link
-- bits on overlapping GUIDs and never delete existing candidate rows.
INSERT INTO `manastorm_segment_spawn`
    (`segment_id`, `spawn_guid`, `flags`, `enabled`)
SELECT
    538, ss.`spawn_guid`, (ss.`flags` & 3), 1
FROM `manastorm_segment_spawn` AS ss
JOIN `creature` AS npc ON npc.`guid` = ss.`spawn_guid`
JOIN `manastorm_segment` AS src ON src.`segment_id` = 198
JOIN `manastorm_segment` AS dst ON dst.`segment_id` = 538
WHERE ss.`segment_id` = 198
  AND ss.`enabled` = 1
  AND (ss.`flags` & 3) = 3
  AND npc.`map` = 209
  AND npc.`id` <> COALESCE(
      NULLIF(dst.`runtime_objective_creature_entry`, 0),
      dst.`objective_creature_entry`)
  AND src.`map_id` = 209
  AND src.`objective_creature_entry` = 7273
  AND dst.`map_id` = 209
  AND dst.`objective_creature_entry` = 7795
ON DUPLICATE KEY UPDATE
    `flags` = (`manastorm_segment_spawn`.`flags` | VALUES(`flags`)),
    `enabled` = 1;

INSERT INTO `manastorm_segment_spawn`
    (`segment_id`, `spawn_guid`, `flags`, `enabled`)
SELECT
    548, ss.`spawn_guid`, (ss.`flags` & 3), 1
FROM `manastorm_segment_spawn` AS ss
JOIN `creature` AS npc ON npc.`guid` = ss.`spawn_guid`
JOIN `manastorm_segment` AS src ON src.`segment_id` = 392
JOIN `manastorm_segment` AS dst ON dst.`segment_id` = 548
WHERE ss.`segment_id` = 392
  AND ss.`enabled` = 1
  AND (ss.`flags` & 3) = 3
  AND npc.`map` = 209
  AND npc.`id` <> COALESCE(
      NULLIF(dst.`runtime_objective_creature_entry`, 0),
      dst.`objective_creature_entry`)
  AND src.`map_id` = 209
  AND src.`objective_creature_entry` = 7273
  AND dst.`map_id` = 209
  AND dst.`objective_creature_entry` = 7795
ON DUPLICATE KEY UPDATE
    `flags` = (`manastorm_segment_spawn`.`flags` | VALUES(`flags`)),
    `enabled` = 1;

-- Copy actual boss Link requirements AFTER copying candidates.
-- Never overwrite a nonzero manually configured Velratha count.
-- Bound the copied requirement to the actual active candidate count,
-- excluding the removed objective-boss candidate. Avoid an unbreakable
-- Link aura when source and destination have different valid rosters.
UPDATE `manastorm_segment` AS dst
JOIN `manastorm_segment` AS src ON src.`segment_id` = 198
SET dst.`chaotic_link_stacks` = LEAST(
    src.`chaotic_link_stacks`,
    (SELECT COUNT(*) FROM `manastorm_segment_spawn` AS activeLinks
     WHERE activeLinks.`segment_id` = dst.`segment_id`
       AND activeLinks.`enabled` = 1
       AND (activeLinks.`flags` & 3) = 3))
WHERE dst.`segment_id` = 538
  AND src.`map_id` = 209
  AND dst.`map_id` = 209
  AND src.`objective_creature_entry` = 7273
  AND dst.`objective_creature_entry` = 7795
  AND dst.`chaotic_link_stacks` = 0
  AND src.`chaotic_link_stacks` > 0;

UPDATE `manastorm_segment` AS dst
JOIN `manastorm_segment` AS src ON src.`segment_id` = 392
SET dst.`chaotic_link_stacks` = LEAST(
    src.`chaotic_link_stacks`,
    (SELECT COUNT(*) FROM `manastorm_segment_spawn` AS activeLinks
     WHERE activeLinks.`segment_id` = dst.`segment_id`
       AND activeLinks.`enabled` = 1
       AND (activeLinks.`flags` & 3) = 3))
WHERE dst.`segment_id` = 548
  AND src.`map_id` = 209
  AND dst.`map_id` = 209
  AND src.`objective_creature_entry` = 7273
  AND dst.`objective_creature_entry` = 7795
  AND dst.`chaotic_link_stacks` = 0
  AND src.`chaotic_link_stacks` > 0;

-- Review both tracks, copied links and their required break counts:
-- SELECT s.segment_id, s.objective_creature_entry,
--        s.dungeon_encounter_id, s.start_game_tele_id,
--        s.chaotic_link_stacks, s.enabled,
--        COUNT(IF(ss.enabled = 1 AND (ss.flags & 2) <> 0, 1, NULL))
--            AS active_link_candidates
-- FROM manastorm_segment AS s
-- LEFT JOIN manastorm_segment_spawn AS ss
--     ON ss.segment_id = s.segment_id
-- WHERE s.segment_id IN (198, 538, 392, 548)
-- GROUP BY s.segment_id, s.objective_creature_entry,
--          s.dungeon_encounter_id, s.start_game_tele_id,
--          s.chaotic_link_stacks, s.enabled
-- ORDER BY s.segment_id;
