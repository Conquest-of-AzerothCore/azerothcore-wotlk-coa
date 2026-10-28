-- Seed of Overgrowth (1345123) on the Dustwallow Marsh road floated 0.6 yd above the ground: the map pass put it at
-- 32.826, but the terrain under (-3538.0, -2811.8) is at 32.20 (Map::GetHeight).
UPDATE `gameobject` SET `position_z` = 32.20 WHERE `guid` = 6942151 AND `id` = 1345123;
