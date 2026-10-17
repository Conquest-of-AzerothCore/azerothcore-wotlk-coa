-- Zul'Farrak / Hydromancer Velratha: repair copied boss self-links.
--
-- In the earlier 111 migration, Ghaz'rilla's 198 / 392 Link roster included
-- Velratha's native DB creature 81570 (entry 7795). The copy incorrectly
-- included it in Velratha's own 538 / 548 Link roster, producing:
--   segment 538 -> spawn 81570 (7795) with flags 0x3
--   segment 548 -> spawn 81570 (7795) with flags 0x3
-- The Manastorm datastore correctly rejects the objective boss as route trash.
--
-- The corrected 111 migration now filters out the target objective creature
-- entry at copy time. This additional migration repairs databases that
-- already imported the earlier 111. It is safe to execute repeatedly.
-- Do NOT remove the boss's creature world spawn or Ghaz'rilla's source links.

-- Remove only the exact known copied self-link rows. A genuine DB spawn
-- of objective entry 7795 on map 209 must be present, and flags must
-- still be exactly RouteCreature|ChaoticLinkEligible (0x3).
DELETE ss
FROM `manastorm_segment_spawn` AS ss
JOIN `manastorm_segment` AS seg
  ON seg.`segment_id` = ss.`segment_id`
JOIN `creature` AS c
  ON c.`guid` = ss.`spawn_guid`
WHERE ss.`segment_id` IN (538, 548)
  AND ss.`spawn_guid` = 81570
  AND ss.`flags` = 3
  AND seg.`map_id` = 209
  AND seg.`objective_creature_entry` = 7795
  AND c.`map` = 209
  AND c.`id` = 7795;

-- The source boss's requirement may have been copied before excluding
-- this self-link. Clamp only invalid target requirements to the remaining
-- enabled eligible trash count; never alter Ghaz'rilla's 198 / 392 stages.
-- Keep manually authored smaller counts unchanged.
UPDATE `manastorm_segment` AS seg
SET seg.`chaotic_link_stacks` = LEAST(
    seg.`chaotic_link_stacks`,
    (SELECT COUNT(*)
     FROM `manastorm_segment_spawn` AS ss
     JOIN `creature` AS c ON c.`guid` = ss.`spawn_guid`
     WHERE ss.`segment_id` = seg.`segment_id`
       AND ss.`enabled` = 1
       AND (ss.`flags` & 3) = 3
       AND c.`map` = 209
       AND c.`id` <> 7795))
WHERE seg.`segment_id` IN (538, 548)
  AND seg.`map_id` = 209
  AND seg.`objective_creature_entry` = 7795;

-- Check that no boss self-links remain and required links fit candidates:
-- SELECT seg.segment_id, seg.chaotic_link_stacks,
--        COUNT(ss.spawn_guid) AS valid_link_candidates
-- FROM manastorm_segment AS seg
-- LEFT JOIN manastorm_segment_spawn AS ss
--   ON ss.segment_id = seg.segment_id
--   AND ss.enabled = 1
--   AND (ss.flags & 3) = 3
--   AND EXISTS (
--       SELECT 1 FROM creature AS c
--       WHERE c.guid = ss.spawn_guid AND c.map = 209 AND c.id <> 7795)
-- WHERE seg.segment_id IN (538, 548)
-- GROUP BY seg.segment_id, seg.chaotic_link_stacks;
