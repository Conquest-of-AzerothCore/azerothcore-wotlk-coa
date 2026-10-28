-- Rivenruin Cave: half the Rivenruin Myrmidons and every Rivenruin Sorceress stood still, so the naga looked frozen next
-- to the ones wandering the hall floors. They now wander 3 yd too; random movement follows the navmesh and rejects
-- drops, so the balcony and ledge spawns stay on them. The Rivenruin Brute keeps its post.
UPDATE `creature` SET `MovementType` = 1, `wander_distance` = 3 WHERE `id` IN (162834, 162835) AND `guid` BETWEEN 9012330 AND 9012385 AND `MovementType` = 0;
