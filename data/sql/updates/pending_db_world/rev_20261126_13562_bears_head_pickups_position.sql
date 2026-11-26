-- On the Importance of Arcane Foci (Arcane Tome, entry 254412, guid 6942004, Azshara)
-- was moved by 2026_09_23_05_worldforged_map.sql:2056 to (3989.600, -4750.800, 304.846),
-- 4.13 yd below .map terrain (308.977) outside Redridge_Magetower.wmo (#13562).
-- Restore first-pass realm-dump row 6900182 (2026_09_16_00_worldforged_pickups.sql:3422)
-- inside the upper tower room (floorZ 296.019, headroom 6.993 yd).
UPDATE `gameobject`
SET `position_x` = 3994.597,
    `position_y` = -4766.068,
    `position_z` = 296.604
WHERE `guid` = 6942004 AND `id` = 254412;

-- Bear's Head Apprentice Robe (entry 9900009, guid 6970005, Azshara, drops item 354276)
-- was placed by rev_20261014_95_worldforged_lootcollector_alignment.sql:111 at
-- (3984.770, -4789.890, 266.609), on .map terrain 3.72 yd beneath the Redridge_Magetower.wmo
-- ground floor (270.331) (#13562).
-- Restore first-pass realm-dump row 6900184 (2026_09_16_00_worldforged_pickups.sql:3424)
-- flush on the tower ground floor (-0.016 yd to floorZ 270.331).
UPDATE `gameobject`
SET `position_x` = 3984.786,
    `position_y` = -4793.709,
    `position_z` = 270.315
WHERE `guid` = 6970005 AND `id` = 9900009;
