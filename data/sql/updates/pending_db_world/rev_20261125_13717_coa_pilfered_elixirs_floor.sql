-- Pilfered Elixirs (object 480103, guid 9001102), Jansen Stead, Westfall (#13717): the crate for Potions for Sentinel
-- Hill (1313) sat 0.59 yd under the farmhouse floor (spawn_ground_gap -0.587) with a wall through it
-- (spawn_clearance 0.19 yd). It moves 1.4 yd onto the open floor, the nearest point of a measured 1 yd grid with
-- 2.18 yd clearance, at the floor's ground height (z 34.0).
UPDATE `gameobject` SET `position_x` = -9846.18, `position_y` = 1037.06, `position_z` = 34.0
WHERE `guid` = 9001102 AND `id` = 480103 AND `map` = 0
    AND `position_x` BETWEEN -9845.19 AND -9845.17
    AND `position_y` BETWEEN 1036.05 AND 1036.07
    AND `position_z` BETWEEN 33.40 AND 33.42;
