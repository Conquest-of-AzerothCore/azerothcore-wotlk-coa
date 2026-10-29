-- Adventurer's Lost Sack (#8770): the Shadowglen realm-map pass left the Forgotten Sack
-- (gameobject guid 6941386, entry 90636) floating 0.57 yd above the road (confirmed with the
-- gameplay harness's own ground probe: spawn_ground_gap +0.565308). The pickup's own first-pass
-- position sat exactly on the Stonebench01 seat 7 yd away (vmap top 1362.046, harness
-- point_ground_gap +0.004272 there); move it back onto the bench.

UPDATE `gameobject`
SET `position_x` = 10207.9, `position_y` = 700.331, `position_z` = 1362.05
WHERE `guid` = 6941386 AND `id` = 90636 AND `map` = 1
  AND `position_x` BETWEEN 10211.2 AND 10212.2 AND `position_y` BETWEEN 693.7 AND 694.7;
