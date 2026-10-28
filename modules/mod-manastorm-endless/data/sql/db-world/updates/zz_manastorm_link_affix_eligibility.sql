-- Linked route creatures are eligible for affix selection.
-- Preserve enabled states, other roles, authored stacks and route tuning.
UPDATE `manastorm_segment_spawn`
SET `flags` = `flags` | 17
WHERE (`flags` & 2) <> 0
  AND (`flags` & 17) <> 17;
