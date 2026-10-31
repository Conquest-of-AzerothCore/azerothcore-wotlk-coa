-- Worldforged pickups reported floating, sunk or buried, set on the ground the server finds under them (Map::GetHeight from above, the nearby_gameobject_ground_offset metric).
-- 2026_09_23_06_worldforged_recorded_heights had moved several of them by sightings taken elsewhere; for those the ground is the 2026_09_23_05_worldforged_map height again.
UPDATE `gameobject` SET `position_z` = 277.070 WHERE `guid` = 6941026 AND `id` = 158330 AND ABS(`position_z` - 289.769) < 0.01;  -- Scorched Greatblade (#10499), was +12.70 yd off the ground
UPDATE `gameobject` SET `position_z` = 397.389 WHERE `guid` = 6941438 AND `id` = 517276 AND ABS(`position_z` - 415.814) < 0.01;  -- Bitterbranch Claymore (#10464), was +18.43 yd off the ground
UPDATE `gameobject` SET `position_z` = 34.147 WHERE `guid` = 6940792 AND `id` = 95847 AND ABS(`position_z` - 37.680) < 0.01;  -- Musty Horse Blanket (#10446), was +3.53 yd off the ground
UPDATE `gameobject` SET `position_z` = 282.476 WHERE `guid` = 6940216 AND `id` = 66601 AND ABS(`position_z` - 283.043) < 0.01;  -- Caravan Crossbow (#10116), was +0.57 yd off the ground
UPDATE `gameobject` SET `position_z` = 133.303 WHERE `guid` = 6940475 AND `id` = 254657 AND ABS(`position_z` - 133.572) < 0.01;  -- Firebrand Libram (#10119), was +0.27 yd off the ground
UPDATE `gameobject` SET `position_z` = 234.868 WHERE `guid` = 6941383 AND `id` = 517275 AND ABS(`position_z` - 235.627) < 0.01;  -- Acid Bolter (#10461), was +0.76 yd off the ground
UPDATE `gameobject` SET `position_z` = 100.867 WHERE `guid` = 6940497 AND `id` = 95860 AND ABS(`position_z` - 101.768) < 0.01;  -- Forgotten Fitted Pants (#10487), was +0.90 yd off the ground
UPDATE `gameobject` SET `position_z` = 241.695 WHERE `guid` = 6941002 AND `id` = 518348 AND ABS(`position_z` - 242.028) < 0.01;  -- Sandworn Arcanist Staff (#10494), was +0.33 yd off the ground
UPDATE `gameobject` SET `position_z` = 36.799 WHERE `guid` = 6940568 AND `id` = 95877 AND ABS(`position_z` - 38.446) < 0.01;  -- Grave Spite (#10451), was +1.65 yd off the ground
UPDATE `gameobject` SET `position_z` = 29.581 WHERE `guid` = 6941547 AND `id` = 95639 AND ABS(`position_z` - 30.738) < 0.01;  -- Centaur Axe (#10405), was +1.16 yd off the ground
UPDATE `gameobject` SET `position_z` = 86.438 WHERE `guid` = 6942215 AND `id` = 254275 AND ABS(`position_z` - 85.995) < 0.01;  -- Sorrow of the Kodo (#10471), was -0.44 yd off the ground
UPDATE `gameobject` SET `position_z` = 49.918 WHERE `guid` = 6941373 AND `id` = 95732 AND ABS(`position_z` - 49.808) < 0.01;  -- Zul'Kunda Tribe Trophy (#10144), was -0.11 yd off the ground
UPDATE `gameobject` SET `position_z` = 79.815 WHERE `guid` = 6942443 AND `id` = 90292 AND ABS(`position_z` - 76.039) < 0.01;  -- Worn Grunt Axe (#10484), was -3.78 yd off the ground
UPDATE `gameobject` SET `position_z` = 250.057 WHERE `guid` = 6940392 AND `id` = 518346 AND ABS(`position_z` - 247.669) < 0.01;  -- Duststorm Sash (#10115), was -2.39 yd off the ground
