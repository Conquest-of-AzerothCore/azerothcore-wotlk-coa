-- Worldforged Bloodscorn Ritual Kris (#1457): the pickup in Rage Scar Hold, Feralas (gameobject guid
-- 6941461, entry 96131, item 515204) floats 1.76 yd above the cave floor. Its X/Y is the recorded
-- Ascension find position (sidekick zone-122 pin 0.5463/0.3201 converts through WorldMapArea bounds to
-- world -3848.9, 1642.0), so only the height is wrong: the realm-map pass kept a z of 146.345. Measured
-- with spawn_ground_gap against the live map/vmap data; lower it onto the measured floor.
UPDATE `gameobject` SET `position_z` = 144.583
 WHERE `guid` = 6941461 AND `id` = 96131 AND `map` = 1
   AND `position_x` BETWEEN -3849.9 AND -3847.9 AND `position_y` BETWEEN 1641.0 AND 1643.0
   AND ABS(`position_z` - 146.345) < 0.01;
