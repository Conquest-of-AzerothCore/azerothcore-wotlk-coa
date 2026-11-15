-- Worldforged pickups and an ore spot reported floating or buried, set on the ground the server finds above them (Map::GetHeight from above, the nearby_gameobject_ground_offset metric).
UPDATE `gameobject` SET `position_z` = -216.653 WHERE `guid` = 6942240 AND `id` = 96218 AND ABS(`position_z` - -207.499) < 0.01;  -- Steel Helmet (#10627), was 9.15 yd above the ground
UPDATE `gameobject` SET `position_z` = 102.528 WHERE `guid` = 6940531 AND `id` = 90534 AND ABS(`position_z` - 101.371) < 0.01;  -- Darrowshire Cloak (#10683), was 1.16 yd under the ground
UPDATE `gameobject` SET `position_z` = 244.555 WHERE `guid` = 6941125 AND `id` = 518055 AND ABS(`position_z` - 245.248) < 0.01;  -- Extra Crate (#10603), was 0.69 yd above the ground
UPDATE `gameobject` SET `position_z` = -262.480 WHERE `guid` = 12020694 AND `id` = 324 AND ABS(`position_z` - -260.540) < 0.01;  -- Small Thorium Vein (#10631), was 1.94 yd above the ground
