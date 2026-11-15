-- Worldforged pickups reported floating, sunk or buried, set on the ground the server finds under them (Map::GetHeight from above, the nearby_gameobject_ground_offset metric).
-- 2026_09_23_06_worldforged_recorded_heights had moved several of them by sightings taken elsewhere; for those the ground is the 2026_09_23_05_worldforged_map height again.
UPDATE `gameobject` SET `position_z` = 277.070 WHERE `guid` = 6941026 AND `id` = 158330 AND `position_z` BETWEEN 289.759 AND 289.779;  -- Scorched Greatblade (#10499), was +12.70 yd off the ground
UPDATE `gameobject` SET `position_z` = 397.389 WHERE `guid` = 6941438 AND `id` = 517276 AND `position_z` BETWEEN 415.804 AND 415.824;  -- Bitterbranch Claymore (#10464), was +18.43 yd off the ground
UPDATE `gameobject` SET `position_z` = 34.147 WHERE `guid` = 6940792 AND `id` = 95847 AND `position_z` BETWEEN 37.670 AND 37.690;  -- Musty Horse Blanket (#10446), was +3.53 yd off the ground
UPDATE `gameobject` SET `position_z` = 282.476 WHERE `guid` = 6940216 AND `id` = 66601 AND `position_z` BETWEEN 283.033 AND 283.053;  -- Caravan Crossbow (#10116), was +0.57 yd off the ground
UPDATE `gameobject` SET `position_z` = 133.303 WHERE `guid` = 6940475 AND `id` = 254657 AND `position_z` BETWEEN 133.562 AND 133.582;  -- Firebrand Libram (#10119), was +0.27 yd off the ground
UPDATE `gameobject` SET `position_z` = 234.868 WHERE `guid` = 6941383 AND `id` = 517275 AND `position_z` BETWEEN 235.617 AND 235.637;  -- Acid Bolter (#10461), was +0.76 yd off the ground
UPDATE `gameobject` SET `position_z` = 100.867 WHERE `guid` = 6940497 AND `id` = 95860 AND `position_z` BETWEEN 101.758 AND 101.778;  -- Forgotten Fitted Pants (#10487), was +0.90 yd off the ground
UPDATE `gameobject` SET `position_z` = 241.695 WHERE `guid` = 6941002 AND `id` = 518348 AND `position_z` BETWEEN 242.018 AND 242.038;  -- Sandworn Arcanist Staff (#10494), was +0.33 yd off the ground
UPDATE `gameobject` SET `position_z` = 36.799 WHERE `guid` = 6940568 AND `id` = 95877 AND `position_z` BETWEEN 38.436 AND 38.456;  -- Grave Spite (#10451), was +1.65 yd off the ground
UPDATE `gameobject` SET `position_z` = 29.581 WHERE `guid` = 6941547 AND `id` = 95639 AND `position_z` BETWEEN 30.728 AND 30.748;  -- Centaur Axe (#10405), was +1.16 yd off the ground
UPDATE `gameobject` SET `position_z` = 86.438 WHERE `guid` = 6942215 AND `id` = 254275 AND `position_z` BETWEEN 85.985 AND 86.005;  -- Sorrow of the Kodo (#10471), was -0.44 yd off the ground
UPDATE `gameobject` SET `position_z` = 79.815 WHERE `guid` = 6942443 AND `id` = 90292 AND `position_z` BETWEEN 76.029 AND 76.049;  -- Worn Grunt Axe (#10484), was -3.78 yd off the ground
UPDATE `gameobject` SET `position_z` = 250.057 WHERE `guid` = 6940392 AND `id` = 518346 AND `position_z` BETWEEN 247.659 AND 247.679;  -- Duststorm Sash (#10115), was -2.39 yd off the ground
