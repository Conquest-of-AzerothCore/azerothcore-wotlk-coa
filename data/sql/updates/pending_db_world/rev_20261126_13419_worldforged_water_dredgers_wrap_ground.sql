-- Worldforged Water Dredger's Wrap (Waterlogged Chest 95923, guid 6942409), Un'Goro Crater (#13419):
-- the realm-map pass moved the pickup 5.62 yd south from first-pass row 6901321 (-7027.380, -1161.780)
-- and kept that row's z -274.259, so it sat 0.80 yd under the slope. New z: the server's terrain height
-- at (-7027.300, -1167.400) from 0014534.map (-273.462; zero vmap models within 50 yd).
UPDATE `gameobject` SET `position_z` = -273.462
WHERE `guid` = 6942409 AND `id` = 95923 AND `map` = 1 AND `position_z` BETWEEN -274.264 AND -274.254;
