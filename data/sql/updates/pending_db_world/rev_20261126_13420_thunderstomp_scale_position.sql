-- #13420: Restore Preserved Dermal Plate (guid 6942322, entry 95918, drops Thunderstomp Scale 515372)
-- in Un'Goro Crater to its first-pass realm-dump coordinates (row 6901316, +0.075 yd above terrain)
-- instead of the realm-map pass spot where it sat 0.60 yd underground.
UPDATE `gameobject`
SET `position_x` = -7823.470, `position_y` = -923.311, `position_z` = -269.053
WHERE `guid` = 6942322 AND `id` = 95918;
