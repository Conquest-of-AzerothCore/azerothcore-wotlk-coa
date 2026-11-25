-- #12371: Mulgore Tree 8000670 (rev_20260928_82, re-inserted unchanged by the GatherMate revert) lay 13.18 yd
-- under the ground. Raise it to the ground height the server maps give at its x/y (3.762).
UPDATE `gameobject` SET `position_z` = 3.762
WHERE `guid` = 8000670 AND `id` = 244629 AND `map` = 1 AND `position_z` BETWEEN -9.44 AND -9.41;
