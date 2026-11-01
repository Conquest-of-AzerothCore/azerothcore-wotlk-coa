-- Woodcutting Dun Morogh Tree guid 8000225 (#10496) stands in Searing Gorge, 800 yd from the nearest other
-- spawn of its entry (rev_20260928_82_woodcutting_spawns.sql). Remove the stray spawn.
DELETE FROM `gameobject`
WHERE `guid` = 8000225 AND `id` = 244620 AND `map` = 0 AND `position_x` BETWEEN -6938 AND -6936;
