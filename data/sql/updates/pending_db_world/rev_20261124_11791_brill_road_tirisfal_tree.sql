-- Tirisfal Tree woodcutting node 8000416 (#11791): the GatherMate revert (rev_20261105_100, #11290) re-inserted it on
-- the stone road into west Brill. Re-apply the #8932 placement from rev_20261024_95, 9 yd west on the grass.
UPDATE `gameobject` SET `position_x` = 2244.4, `position_y` = 509.3, `position_z` = 35.152
WHERE `guid` = 8000416 AND `id` = 244624 AND `map` = 0
  AND `position_x` BETWEEN 2253.3 AND 2253.5
  AND `position_y` BETWEEN 509.2 AND 509.4;
