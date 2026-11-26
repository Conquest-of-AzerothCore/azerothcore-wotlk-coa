-- Hull Wood Hunk (Wooden Plank, entry 515827, guid 6941843, Tanaris) was placed by
-- 2026_09_23_05_worldforged_map.sql:1895 at (-7808.400, -5001.100, 46.525), using the
-- .map mountain terrain height (46.525) 40.72 yd above the Md_Warmcavetunnel01.wmo
-- cave tunnel floor (5.804) where the reporter stood 2.84 yd away (#13434).
-- Lower guid 6941843 onto the Md_Warmcavetunnel01.wmo tunnel floor at z = 5.804.
UPDATE `gameobject`
SET `position_z` = 5.804
WHERE `guid` = 6941843 AND `id` = 515827;
