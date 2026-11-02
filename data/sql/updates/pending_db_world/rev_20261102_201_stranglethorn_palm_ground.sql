-- The Stranglethorn Palm west of Nesingwary's camp (guid 12010413) was imported at z 8.94, under the ground the
-- player stands on there (15.82 measured by the server's own height query from above), so it could be tracked
-- but not cut: "too far away" (#10735). Raise it onto that ground.
UPDATE `gameobject` SET `position_z` = 15.82 WHERE `guid` = 12010413 AND `id` = 244638 AND `map` = 0;
