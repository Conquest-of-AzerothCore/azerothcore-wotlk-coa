-- ----------------------------------------------------------------------------
-- Worldforged pickups: the rows the realm's own occupants disagree with.
-- ----------------------------------------------------------------------------
-- A pickup's position was recorded as X and Y only: a pin marks where a player stood
-- when the loot window opened. The earlier passes gave each row a height from the
-- terrain surface or from the nearest object; this one corrects the rows where the
-- props and creatures that actually live there disagree with the height it carries.
--
-- A row moves when three or more occupants of the realm stand within 15 yd, agree with
-- each other to within 20 yd, and place their median more than 5 yd from the row: the
-- row takes that median, which is the floor of the room, cave or terrace the pickup
-- was looted on. A row also moves when nothing at all stands within 15 yd and it hangs
-- between 8 and 40 yd above the terrain surface: it floats in open air and takes the
-- terrain.
-- 69 rows.

UPDATE `gameobject` SET
    `position_z` = CASE `guid`
        WHEN 6900012 THEN 239.5475
        WHEN 6900018 THEN 277.0654
        WHEN 6900032 THEN 237.1221
        WHEN 6900114 THEN 166.8637
        WHEN 6900125 THEN 142.3927
        WHEN 6900164 THEN 8.7593
        WHEN 6900165 THEN 9.3993
        WHEN 6900198 THEN 21.7302
        WHEN 6900215 THEN 144.9169
        WHEN 6900217 THEN -4.8735
        WHEN 6900340 THEN 159.762
        WHEN 6900373 THEN 52.5756
        WHEN 6900379 THEN 168.3765
        WHEN 6900406 THEN 40.2621
        WHEN 6900418 THEN 89.5608
        WHEN 6900438 THEN 1307.89
        WHEN 6900439 THEN 1241.2355
        WHEN 6900441 THEN 1328.254
        WHEN 6900452 THEN 11.7208
        WHEN 6900462 THEN -67.9169
        WHEN 6900472 THEN -67.9169
        WHEN 6900473 THEN -67.9169
        WHEN 6900528 THEN 5.0378
        WHEN 6900554 THEN 20.5852
        WHEN 6900555 THEN 57.3431
        WHEN 6900576 THEN -12.0031
        WHEN 6900605 THEN 397.2523
        WHEN 6900621 THEN 3.3947
        WHEN 6900639 THEN 310.831
        WHEN 6900688 THEN 35.7766
        WHEN 6900727 THEN 129.9704
        WHEN 6900741 THEN 62.1823
        WHEN 6900791 THEN 164.404
        WHEN 6900800 THEN 176.5599
        WHEN 6900809 THEN 3.2195
        WHEN 6900891 THEN 80.0211
        WHEN 6900939 THEN 57.3921
        WHEN 6901022 THEN 377.7735
        WHEN 6901043 THEN 285.0527
        WHEN 6901102 THEN 237.245
        WHEN 6901113 THEN 406.331
        WHEN 6901237 THEN 91.7485
        WHEN 6901273 THEN -48.0569
        WHEN 6901338 THEN 93.8771
        WHEN 6901348 THEN 45.9542
        WHEN 6901375 THEN 51.3487
        WHEN 6901497 THEN 164.948
        WHEN 6903283 THEN 420.5176
        WHEN 6903582 THEN 84.4108
        WHEN 6903870 THEN 77.4244
        WHEN 6904112 THEN 127.155
        WHEN 6904115 THEN 102.0543
        WHEN 6904294 THEN 27.2385
        WHEN 6904297 THEN 32.5926
        WHEN 6904303 THEN 30.9023
        WHEN 6904358 THEN 102.0798
        WHEN 6904428 THEN 14.4042
        WHEN 6904650 THEN 30.7495
        WHEN 6904924 THEN 76.7928
        WHEN 6905084 THEN -52.1213
        WHEN 6905111 THEN 35.5474
        WHEN 6905144 THEN 103.6398
        WHEN 6905146 THEN -62.0318
        WHEN 6905275 THEN -138.042
        WHEN 6910220 THEN 4.8857
        WHEN 6910382 THEN 45.5754
        WHEN 6910404 THEN 52.9057
        WHEN 6910448 THEN 73.14
        WHEN 6920010 THEN 82.2999
        ELSE `position_z` END,
    `Comment` = CASE `guid`
        WHEN 6900012 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 256.331, now 239.5475')
        WHEN 6900018 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 289.769, now 277.0654')
        WHEN 6900032 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 258.514, now 237.1221')
        WHEN 6900114 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 185.393, now 166.8637')
        WHEN 6900125 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 153.991, now 142.3927')
        WHEN 6900164 THEN CONCAT(`Comment`, ' | ground: floor of 4 occupants within 15 yd, was 27.724, now 8.7593')
        WHEN 6900165 THEN CONCAT(`Comment`, ' | ground: floor of 7 occupants within 15 yd, was 16.29, now 9.3993')
        WHEN 6900198 THEN CONCAT(`Comment`, ' | ground: floor of 3 occupants within 15 yd, was 34.063, now 21.7302')
        WHEN 6900215 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 155.508, now 144.9169')
        WHEN 6900217 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 10.144, now -4.8735')
        WHEN 6900340 THEN CONCAT(`Comment`, ' | ground: floor of 4 occupants within 15 yd, was 145.086, now 159.762')
        WHEN 6900373 THEN CONCAT(`Comment`, ' | ground: floor of 13 occupants within 15 yd, was 31.498, now 52.5756')
        WHEN 6900379 THEN CONCAT(`Comment`, ' | ground: floor of 6 occupants within 15 yd, was 157.782, now 168.3765')
        WHEN 6900406 THEN CONCAT(`Comment`, ' | ground: floor of 5 occupants within 15 yd, was 51.389, now 40.2621')
        WHEN 6900418 THEN CONCAT(`Comment`, ' | ground: floor of 3 occupants within 15 yd, was 69.983, now 89.5608')
        WHEN 6900438 THEN CONCAT(`Comment`, ' | ground: floor of 3 occupants within 15 yd, was 1317.228, now 1307.89')
        WHEN 6900439 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 1251.97, now 1241.2355')
        WHEN 6900441 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 1354.74, now 1328.254')
        WHEN 6900452 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 28.471, now 11.7208')
        WHEN 6900462 THEN CONCAT(`Comment`, ' | ground: floor of 7 occupants within 15 yd, was -81.084, now -67.9169')
        WHEN 6900472 THEN CONCAT(`Comment`, ' | ground: floor of 7 occupants within 15 yd, was -80.734, now -67.9169')
        WHEN 6900473 THEN CONCAT(`Comment`, ' | ground: floor of 7 occupants within 15 yd, was -80.145, now -67.9169')
        WHEN 6900528 THEN CONCAT(`Comment`, ' | ground: floor of 15 occupants within 15 yd, was 14.851, now 5.0378')
        WHEN 6900554 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 54.126, now 20.5852')
        WHEN 6900555 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 67.646, now 57.3431')
        WHEN 6900576 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 15.269, now -12.0031')
        WHEN 6900605 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 415.814, now 397.2523')
        WHEN 6900621 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 22.115, now 3.3947')
        WHEN 6900639 THEN CONCAT(`Comment`, ' | ground: floor of 10 occupants within 15 yd, was 301.731, now 310.831')
        WHEN 6900688 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 73.902, now 35.7766')
        WHEN 6900727 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 156.662, now 129.9704')
        WHEN 6900741 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 84.043, now 62.1823')
        WHEN 6900791 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 187.402, now 164.404')
        WHEN 6900800 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 213.904, now 176.5599')
        WHEN 6900809 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 15.868, now 3.2195')
        WHEN 6900891 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 101.257, now 80.0211')
        WHEN 6900939 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 90.198, now 57.3921')
        WHEN 6901022 THEN CONCAT(`Comment`, ' | ground: floor of 4 occupants within 15 yd, was 382.848, now 377.7735')
        WHEN 6901043 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 310.548, now 285.0527')
        WHEN 6901102 THEN CONCAT(`Comment`, ' | ground: floor of 4 occupants within 15 yd, was 252.056, now 237.245')
        WHEN 6901113 THEN CONCAT(`Comment`, ' | ground: floor of 10 occupants within 15 yd, was 414.356, now 406.331')
        WHEN 6901237 THEN CONCAT(`Comment`, ' | ground: floor of 3 occupants within 15 yd, was 105.78, now 91.7485')
        WHEN 6901273 THEN CONCAT(`Comment`, ' | ground: floor of 4 occupants within 15 yd, was -31.509, now -48.0569')
        WHEN 6901338 THEN CONCAT(`Comment`, ' | ground: floor of 3 occupants within 15 yd, was 81.782, now 93.8771')
        WHEN 6901348 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 61.244, now 45.9542')
        WHEN 6901375 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 72.951, now 51.3487')
        WHEN 6901497 THEN CONCAT(`Comment`, ' | ground: floor of 5 occupants within 15 yd, was 172.091, now 164.948')
        WHEN 6903283 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 432.071, now 420.5176')
        WHEN 6903582 THEN CONCAT(`Comment`, ' | ground: floor of 5 occupants within 15 yd, was 101.104, now 84.4108')
        WHEN 6903870 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 88.094, now 77.4244')
        WHEN 6904112 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 156.662, now 127.155')
        WHEN 6904115 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 136.819, now 102.0543')
        WHEN 6904294 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 44.484, now 27.2385')
        WHEN 6904297 THEN CONCAT(`Comment`, ' | ground: floor of 3 occupants within 15 yd, was 38.2888, now 32.5926')
        WHEN 6904303 THEN CONCAT(`Comment`, ' | ground: floor of 5 occupants within 15 yd, was 36.3753, now 30.9023')
        WHEN 6904358 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 114.216, now 102.0798')
        WHEN 6904428 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 45.067, now 14.4042')
        WHEN 6904650 THEN CONCAT(`Comment`, ' | ground: floor of 4 occupants within 15 yd, was 36.3753, now 30.7495')
        WHEN 6904924 THEN CONCAT(`Comment`, ' | ground: floor of 3 occupants within 15 yd, was 87.56, now 76.7928')
        WHEN 6905084 THEN CONCAT(`Comment`, ' | ground: floor of 3 occupants within 15 yd, was -41.898, now -52.1213')
        WHEN 6905111 THEN CONCAT(`Comment`, ' | ground: floor of 7 occupants within 15 yd, was 45.2382, now 35.5474')
        WHEN 6905144 THEN CONCAT(`Comment`, ' | ground: floor of 6 occupants within 15 yd, was 91.47, now 103.6398')
        WHEN 6905146 THEN CONCAT(`Comment`, ' | ground: floor of 3 occupants within 15 yd, was -45.025, now -62.0318')
        WHEN 6905275 THEN CONCAT(`Comment`, ' | ground: floor of 3 occupants within 15 yd, was -123.535, now -138.042')
        WHEN 6910220 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 17.824, now 4.8857')
        WHEN 6910382 THEN CONCAT(`Comment`, ' | ground: floats in open air, was 71.319, now 45.5754')
        WHEN 6910404 THEN CONCAT(`Comment`, ' | ground: floor of 4 occupants within 15 yd, was 61.168, now 52.9057')
        WHEN 6910448 THEN CONCAT(`Comment`, ' | ground: floor of 5 occupants within 15 yd, was 85.975, now 73.14')
        WHEN 6920010 THEN CONCAT(`Comment`, ' | ground: floor of 5 occupants within 15 yd, was 91.084, now 82.2999')
        ELSE `Comment` END
WHERE `guid` IN (6900012, 6900018, 6900032, 6900114, 6900125, 6900164, 6900165, 6900198, 6900215, 6900217, 6900340, 6900373, 6900379, 6900406, 6900418, 6900438, 6900439, 6900441, 6900452, 6900462, 6900472, 6900473, 6900528, 6900554, 6900555, 6900576, 6900605, 6900621, 6900639, 6900688, 6900727, 6900741, 6900791, 6900800, 6900809, 6900891, 6900939, 6901022, 6901043, 6901102, 6901113, 6901237, 6901273, 6901338, 6901348, 6901375, 6901497, 6903283, 6903582, 6903870, 6904112, 6904115, 6904294, 6904297, 6904303, 6904358, 6904428, 6904650, 6904924, 6905084, 6905111, 6905144, 6905146, 6905275, 6910220, 6910382, 6910404, 6910448, 6920010);
