-- Goblin Cache (Inventor's Sand Band) in Tanaris was 1.50 yd above the ground the server finds above it
-- (Map::GetHeight from above, the nearby_gameobject_ground_offset metric), reported as mid air (#10887).
UPDATE `gameobject` SET `position_z` = 8.152 WHERE `guid` = 6941872 AND `id` = 515738 AND ABS(`position_z` - 9.653) < 0.01;
